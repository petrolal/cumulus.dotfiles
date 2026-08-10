//! Error type shared across all cumulus subcommands.
//!
//! Every fallible operation returns [`Result`]; errors carry a human-readable
//! message that the binary prints once at the process boundary. This replaces
//! the scattered `exit()` calls of the original shell scripts with idiomatic
//! `?`-based propagation.

use std::fmt;

/// A cumulus operation error: a message plus an optional process exit code.
#[derive(Debug)]
pub struct Error {
    message: String,
    code: u8,
}

impl Error {
    /// Create an error with the default exit code (`1`).
    pub fn new(message: impl Into<String>) -> Self {
        Error {
            message: message.into(),
            code: 1,
        }
    }

    /// Create an error with a specific process exit code.
    pub fn with_code(message: impl Into<String>, code: u8) -> Self {
        Error {
            message: message.into(),
            code,
        }
    }

    /// The exit code this error should terminate the process with.
    pub fn code(&self) -> u8 {
        self.code
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.message)
    }
}

impl std::error::Error for Error {}

impl From<std::io::Error> for Error {
    fn from(e: std::io::Error) -> Self {
        Error::new(e.to_string())
    }
}

/// Convenience alias used throughout the crate.
pub type Result<T> = std::result::Result<T, Error>;

/// Return early with a formatted [`Error`] (the idiomatic replacement for the
/// shell `die` helper).
#[macro_export]
macro_rules! bail {
    ($($arg:tt)*) => {
        return ::core::result::Result::Err($crate::error::Error::new(format!($($arg)*)))
    };
}
