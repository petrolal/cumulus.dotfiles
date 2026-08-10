//! Locale-aware sorting that matches shell glob ordering.
//!
//! The shell sorts glob expansions using the active locale's collation (via
//! libc `strcoll`). To keep wallpaper ordering identical to the original
//! scripts we defer to the same C-library routine rather than Rust's byte-wise
//! `Ord`.

use std::cmp::Ordering;
use std::ffi::CString;
use std::os::raw::{c_char, c_int};
use std::os::unix::ffi::OsStrExt;
use std::path::PathBuf;
use std::sync::Once;

// glibc/musl category constant for collation.
const LC_COLLATE: c_int = 3;

extern "C" {
    fn setlocale(category: c_int, locale: *const c_char) -> *mut c_char;
    fn strcoll(a: *const c_char, b: *const c_char) -> c_int;
}

fn init() {
    static ONCE: Once = Once::new();
    ONCE.call_once(|| unsafe {
        // Honour the environment locale (LC_COLLATE/LC_ALL/LANG), like the shell.
        let empty = CString::new("").unwrap();
        setlocale(LC_COLLATE, empty.as_ptr());
    });
}

fn cmp_bytes(a: &[u8], b: &[u8]) -> Ordering {
    match (CString::new(a), CString::new(b)) {
        (Ok(ca), Ok(cb)) => {
            let r = unsafe { strcoll(ca.as_ptr(), cb.as_ptr()) };
            r.cmp(&0)
        }
        // Interior NUL (shouldn't happen for paths): fall back to byte order.
        _ => a.cmp(b),
    }
}

/// Sort paths the way a shell glob would under the active locale.
pub fn sort_paths(paths: &mut [PathBuf]) {
    init();
    paths.sort_by(|a, b| cmp_bytes(a.as_os_str().as_bytes(), b.as_os_str().as_bytes()));
}

/// Sort plain strings under the active locale.
pub fn sort_strings(items: &mut [String]) {
    init();
    items.sort_by(|a, b| cmp_bytes(a.as_bytes(), b.as_bytes()));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sorts_strings_deterministically() {
        let mut v = vec!["b".to_string(), "a".to_string(), "c".to_string()];
        sort_strings(&mut v);
        assert_eq!(v, ["a", "b", "c"]);
    }
}
