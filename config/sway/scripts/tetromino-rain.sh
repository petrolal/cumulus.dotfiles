#!/usr/bin/env bash
# Polyomino Tetromino Rain — passive terminal screen saver.
# Tetromino shapes fall and stack, purely as animation; there is no player
# control, scoring, or line-clear logic. Any keypress exits.

cleanup() { tput cnorm; clear; }
trap cleanup EXIT INT TERM

tput civis
clear

rows=$(( $(tput lines) - 1 ))
cols=$(tput cols)

declare -A locked_color

colors=(31 33 32 36 34 35 91 93 96 92)

shapes=(
  "0,0 0,1 0,2 0,3"
  "0,0 0,1 1,0 1,1"
  "0,0 0,1 0,2 1,1"
  "0,1 0,2 1,0 1,1"
  "0,0 0,1 1,1 1,2"
  "0,0 1,0 1,1 1,2"
  "0,2 1,0 1,1 1,2"
)

put() {
  local r=$1 c=$2 ch=$3 color=$4
  (( r < 0 || r >= rows || c < 0 || c >= cols )) && return
  printf "\033[%d;%dH" $((r + 1)) $((c + 1))
  if [[ -n "$color" ]]; then
    printf "\033[1;%sm%s\033[0m" "$color" "$ch"
  else
    printf "%s" "$ch"
  fi
}

drop_piece() {
  local shape="${shapes[RANDOM % ${#shapes[@]}]}"
  local color="${colors[RANDOM % ${#colors[@]}]}"
  local -a cells
  read -r -a cells <<< "$shape"

  local maxdc=0 cell dc
  for cell in "${cells[@]}"; do
    dc=${cell#*,}
    (( dc > maxdc )) && maxdc=$dc
  done
  local col=$(( RANDOM % (cols - maxdc) ))
  local row=-4

  while :; do
    local next=$((row + 1)) collide=0 dr rr cc
    for cell in "${cells[@]}"; do
      dr=${cell%,*}; dc=${cell#*,}
      rr=$((next + dr)); cc=$((col + dc))
      if (( rr >= rows )) || [[ -n "${locked_color[$rr,$cc]:-}" ]]; then
        collide=1; break
      fi
    done

    for cell in "${cells[@]}"; do
      dr=${cell%,*}; dc=${cell#*,}
      put $((row + dr)) $((col + dc)) " "
    done

    if (( collide )); then
      for cell in "${cells[@]}"; do
        dr=${cell%,*}; dc=${cell#*,}
        rr=$((row + dr)); cc=$((col + dc))
        if (( rr >= 0 )); then
          locked_color[$rr,$cc]=$color
          put "$rr" "$cc" "█" "$color"
        fi
      done
      break
    fi

    row=$next
    for cell in "${cells[@]}"; do
      dr=${cell%,*}; dc=${cell#*,}
      put $((row + dr)) $((col + dc)) "█" "$color"
    done

    read -r -s -n 1 -t 0.06 && exit 0
  done
}

piece_count=0
max_pieces=$(( rows * cols / 8 ))
(( max_pieces < 20 )) && max_pieces=20

while :; do
  drop_piece
  (( piece_count++ ))
  if (( piece_count > max_pieces )); then
    locked_color=()
    piece_count=0
    clear
  fi
  read -r -s -n 1 -t 0.1 && exit 0
done
