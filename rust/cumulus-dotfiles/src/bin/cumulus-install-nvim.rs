// Multi-call shim: dispatch resolves the `install-nvim` command from argv[0].
use std::process::ExitCode;

fn main() -> ExitCode {
    cumulus_dotfiles::dispatch()
}
