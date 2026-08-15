####################################################################
#
# SdkMan
# THIS FILE MUST SORT LAST (highest number prefix) SO IT LOADS AT THE
# END OF THE SHELL STARTUP FOR SDKMAN TO WORK!!!
#
###################################################################
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Cargo (Rust)
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
