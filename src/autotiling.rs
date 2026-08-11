//! `cumulus-autotiling` — Fibonacci spiral autotiling for Sway.
//! Listens to Sway IPC window events and dynamically sets split direction (`splith` / `splitv`)
//! based on focused window dimensions, skipping floating, fullscreen, or tabbed/stacked windows.

use crate::context::Context;
use crate::error::{Error, Result};
use serde::Deserialize;
use std::env;
use std::io::{Read, Write};
use std::os::unix::net::UnixStream;
use std::path::Path;
use std::process::Command;

const MAGIC: &[u8; 6] = b"i3-ipc";
const RUN_COMMAND: u32 = 0;
const SUBSCRIBE: u32 = 2;
const GET_TREE: u32 = 4;

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
struct SwayNode {
    id: Option<i64>,
    name: Option<String>,
    #[serde(rename = "type")]
    node_type: Option<String>,
    layout: Option<String>,
    orientation: Option<String>,
    fullscreen_mode: Option<i64>,
    floating: Option<String>,
    focused: Option<bool>,
    rect: Option<Rect>,
    nodes: Option<Vec<SwayNode>>,
    floating_nodes: Option<Vec<SwayNode>>,
}

#[derive(Debug, Deserialize, Clone, Copy, PartialEq, Eq)]
struct Rect {
    x: i64,
    y: i64,
    width: u64,
    height: u64,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
struct SwayWindowEvent {
    change: String,
    container: Option<SwayNode>,
}

fn get_socket_path() -> Option<String> {
    if let Ok(sock) = env::var("SWAYSOCK") {
        if !sock.is_empty() && Path::new(&sock).exists() {
            return Some(sock);
        }
    }
    if let Ok(out) = Command::new("swaymsg").args(["-t", "get_version"]).output() {
        if out.status.success() {
            if let Ok(sock) = env::var("SWAYSOCK") {
                if !sock.is_empty() && Path::new(&sock).exists() {
                    return Some(sock);
                }
            }
        }
    }
    None
}

fn pack_message(msg_type: u32, payload: &str) -> Vec<u8> {
    let payload_bytes = payload.as_bytes();
    let len = payload_bytes.len() as u32;
    let mut buf = Vec::with_capacity(14 + payload_bytes.len());
    buf.extend_from_slice(MAGIC);
    buf.extend_from_slice(&len.to_le_bytes());
    buf.extend_from_slice(&msg_type.to_le_bytes());
    buf.extend_from_slice(payload_bytes);
    buf
}

fn unpack_header(stream: &mut UnixStream) -> std::io::Result<(u32, String)> {
    let mut header = [0u8; 14];
    stream.read_exact(&mut header)?;
    if &header[0..6] != MAGIC {
        return Err(std::io::Error::new(
            std::io::ErrorKind::InvalidData,
            "Invalid IPC magic header",
        ));
    }
    let length = u32::from_le_bytes(header[6..10].try_into().unwrap());
    let msg_type = u32::from_le_bytes(header[10..14].try_into().unwrap());

    let mut body = vec![0u8; length as usize];
    stream.read_exact(&mut body)?;
    let payload = String::from_utf8_lossy(&body).into_owned();
    Ok((msg_type, payload))
}

fn send_ipc(stream: &mut UnixStream, msg_type: u32, payload: &str) -> std::io::Result<String> {
    let buf = pack_message(msg_type, payload);
    stream.write_all(&buf)?;
    stream.flush()?;
    let (_, resp) = unpack_header(stream)?;
    Ok(resp)
}

fn find_focused<'a>(
    node: &'a SwayNode,
    parent: Option<&'a SwayNode>,
) -> Option<(&'a SwayNode, Option<&'a SwayNode>)> {
    if node.focused == Some(true) {
        return Some((node, parent));
    }
    if let Some(nodes) = &node.nodes {
        for child in nodes {
            if let Some(found) = find_focused(child, Some(node)) {
                return Some(found);
            }
        }
    }
    if let Some(floating_nodes) = &node.floating_nodes {
        for child in floating_nodes {
            if let Some(found) = find_focused(child, Some(node)) {
                return Some(found);
            }
        }
    }
    None
}

fn should_autotile(focused: &SwayNode, parent: Option<&SwayNode>) -> bool {
    // Skip floating containers
    if focused.node_type.as_deref() == Some("floating_con") {
        return false;
    }
    if focused.layout.as_deref() == Some("floating") {
        return false;
    }
    if let Some(floating) = &focused.floating {
        if floating != "auto_off" && floating != "user_off" && floating != "none" && !floating.is_empty() {
            return false;
        }
    }

    // Skip fullscreen containers
    if focused.fullscreen_mode.unwrap_or(0) != 0 {
        return false;
    }

    // Skip if parent container or workspace is tabbed or stacked
    if let Some(p) = parent {
        if let Some(layout) = &p.layout {
            if layout == "tabbed" || layout == "stacked" {
                return false;
            }
        }
    }

    // Skip if focused container itself is tabbed or stacked
    if let Some(layout) = &focused.layout {
        if layout == "tabbed" || layout == "stacked" {
            return false;
        }
    }

    true
}

fn calculate_split(rect: &Rect) -> &'static str {
    if rect.width >= rect.height {
        "splith"
    } else {
        "splitv"
    }
}

pub fn run(_ctx: &Context, args: &[String]) -> Result<()> {
    if args.iter().any(|a| a == "-h" || a == "--help") {
        println!("cumulus-autotiling — Fibonacci spiral autotiling for Sway.");
        println!("Listens to Sway IPC window events and sets split direction automatically.");
        return Ok(());
    }

    let sock_path = get_socket_path().ok_or_else(|| Error::new("SWAYSOCK not available"))?;

    let mut cmd_sock = UnixStream::connect(&sock_path)
        .map_err(|e| Error::new(format!("failed to connect to SWAYSOCK: {e}")))?;
    let mut event_sock = UnixStream::connect(&sock_path)
        .map_err(|e| Error::new(format!("failed to connect to SWAYSOCK: {e}")))?;

    send_ipc(&mut event_sock, SUBSCRIBE, "[\"window\"]")
        .map_err(|e| Error::new(format!("failed to subscribe to sway events: {e}")))?;

    while let Ok((_, payload)) = unpack_header(&mut event_sock) {
        let is_target_event = if let Ok(event) = serde_json::from_str::<SwayWindowEvent>(&payload) {
            matches!(event.change.as_str(), "focus" | "new" | "move")
        } else {
            payload.contains("\"change\":\"focus\"")
                || payload.contains("\"change\": \"focus\"")
                || payload.contains("\"change\":\"new\"")
                || payload.contains("\"change\": \"new\"")
                || payload.contains("\"change\":\"move\"")
                || payload.contains("\"change\": \"move\"")
        };

        if is_target_event {
            if let Ok(tree_payload) = send_ipc(&mut cmd_sock, GET_TREE, "") {
                if let Ok(root) = serde_json::from_str::<SwayNode>(&tree_payload) {
                    if let Some((focused, parent)) = find_focused(&root, None) {
                        if should_autotile(focused, parent) {
                            if let Some(rect) = focused.rect {
                                if rect.width > 0 && rect.height > 0 {
                                    let cmd = calculate_split(&rect);
                                    let current_orientation =
                                        focused.orientation.as_deref().unwrap_or("none");
                                    let is_already_target = match cmd {
                                        "splith" => current_orientation == "horizontal",
                                        "splitv" => current_orientation == "vertical",
                                        _ => false,
                                    };

                                    if !is_already_target {
                                        let _ = send_ipc(&mut cmd_sock, RUN_COMMAND, cmd);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_find_focused_and_calculate_split() {
        let sample = r#"{
            "id": 1,
            "focused": false,
            "rect": { "x": 0, "y": 0, "width": 3840, "height": 1080 },
            "nodes": [
                {
                    "id": 2,
                    "type": "con",
                    "focused": true,
                    "rect": { "x": 0, "y": 0, "width": 1920, "height": 1080 }
                }
            ]
        }"#;
        let root: SwayNode = serde_json::from_str(sample).unwrap();
        let (focused, parent) = find_focused(&root, None).unwrap();
        assert_eq!(focused.id, Some(2));
        assert!(parent.is_some());
        assert!(should_autotile(focused, parent));
        assert_eq!(calculate_split(&focused.rect.unwrap()), "splith");
    }

    #[test]
    fn test_vertical_split_calculation() {
        let sample = r#"{
            "id": 1,
            "focused": true,
            "type": "con",
            "rect": { "x": 0, "y": 0, "width": 960, "height": 1080 }
        }"#;
        let root: SwayNode = serde_json::from_str(sample).unwrap();
        let (focused, parent) = find_focused(&root, None).unwrap();
        assert_eq!(calculate_split(&focused.rect.unwrap()), "splitv");
        assert!(should_autotile(focused, parent));
    }

    #[test]
    fn test_skip_floating_and_tabbed() {
        let floating_sample = r#"{
            "id": 1,
            "focused": true,
            "type": "floating_con",
            "rect": { "x": 100, "y": 100, "width": 800, "height": 600 }
        }"#;
        let root: SwayNode = serde_json::from_str(floating_sample).unwrap();
        let (focused, parent) = find_focused(&root, None).unwrap();
        assert!(!should_autotile(focused, parent));

        let tabbed_parent_sample = r#"{
            "id": 1,
            "focused": false,
            "layout": "tabbed",
            "nodes": [
                {
                    "id": 2,
                    "focused": true,
                    "type": "con",
                    "rect": { "x": 0, "y": 0, "width": 1920, "height": 1080 }
                }
            ]
        }"#;
        let root: SwayNode = serde_json::from_str(tabbed_parent_sample).unwrap();
        let (focused, parent) = find_focused(&root, None).unwrap();
        assert!(!should_autotile(focused, parent));
    }
}

