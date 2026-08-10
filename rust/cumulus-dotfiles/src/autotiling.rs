//! `cumulus-autotiling` — Fibonacci spiral autotiling for Sway.
//! Ports `scripts/autotiling.py` to std Rust.

use crate::context::Context;
use crate::error::{Error, Result};
use std::env;
use std::io::{Read, Write};
use std::os::unix::net::UnixStream;
use std::path::Path;
use std::process::Command;

const MAGIC: &[u8; 6] = b"i3-ipc";
const RUN_COMMAND: u32 = 0;
const SUBSCRIBE: u32 = 2;
const GET_TREE: u32 = 4;

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

#[derive(Debug, PartialEq, Eq)]
struct Rect {
    width: u64,
    height: u64,
}

fn find_focused_rect(json_str: &str) -> Option<Rect> {
    let focused_idx = json_str
        .find("\"focused\": true")
        .or_else(|| json_str.find("\"focused\":true"))?;

    let rect_idx = json_str[focused_idx..].find("\"rect\"")?;
    let rect_substr = &json_str[focused_idx + rect_idx..];

    let width_val = extract_json_number(rect_substr, "width")?;
    let height_val = extract_json_number(rect_substr, "height")?;

    Some(Rect {
        width: width_val,
        height: height_val,
    })
}

fn extract_json_number(s: &str, key: &str) -> Option<u64> {
    let pattern = format!("\"{key}\"");
    let key_idx = s.find(&pattern)?;
    let after_key = &s[key_idx + pattern.len()..];
    let colon_idx = after_key.find(':')?;
    let num_str = after_key[colon_idx + 1..]
        .trim_start()
        .chars()
        .take_while(|c| c.is_ascii_digit())
        .collect::<String>();
    num_str.parse::<u64>().ok()
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
        let is_focus =
            payload.contains("\"change\":\"focus\"") || payload.contains("\"change\": \"focus\"");
        let is_new =
            payload.contains("\"change\":\"new\"") || payload.contains("\"change\": \"new\"");

        if is_focus || is_new {
            if let Ok(tree_payload) = send_ipc(&mut cmd_sock, GET_TREE, "") {
                if let Some(rect) = find_focused_rect(&tree_payload) {
                    if rect.width > 0 && rect.height > 0 {
                        let cmd = if rect.width >= rect.height {
                            "splith"
                        } else {
                            "splitv"
                        };
                        let _ = send_ipc(&mut cmd_sock, RUN_COMMAND, cmd);
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
    fn test_find_focused_rect() {
        let sample = r#"{
            "id": 1,
            "focused": false,
            "rect": { "width": 3840, "height": 1080 },
            "nodes": [
                {
                    "id": 2,
                    "focused": true,
                    "rect": { "x": 0, "y": 0, "width": 1920, "height": 1080 }
                }
            ]
        }"#;
        let rect = find_focused_rect(sample).unwrap();
        assert_eq!(rect.width, 1920);
        assert_eq!(rect.height, 1080);
    }

    #[test]
    fn test_extract_json_number() {
        let snippet = r#""rect": { "x": 100, "y": 200, "width": 1920, "height": 1080 }"#;
        assert_eq!(extract_json_number(snippet, "width"), Some(1920));
        assert_eq!(extract_json_number(snippet, "height"), Some(1080));
    }
}
