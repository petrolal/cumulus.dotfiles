#!/usr/bin/env bash
# Polyomino Terminal Matrix / Tetromino Screen Saver

if command -v cmatrix >/dev/null 2>&1; then
  exec cmatrix -C yellow
elif command -v bastet >/dev/null 2>&1; then
  exec bastet
elif command -v tint >/dev/null 2>&1; then
  exec tint
else
  clear
  # Static Polyomino Matrix Screen in Axé Gold (#EBB434) and Maré Teal (#00D2D3)
  printf "\033[1;33m"
  cat << 'EOF'
 ╔═════════════════════════════════════════════════════════════════════════╗
 ║                  [⊞] POLYOMINO MATRIX IDLE SCREEN [⊞]                   ║
 ║                                                                         ║
 ║      .-------.-------.-------.                  .-------.               ║
 ║     /       /       /       /|                 /       /|               ║
 ║    +-------+-------+-------+ |                +-------+ |               ║
 ║    |       |       |       | |                |       | |               ║
 ║    |       |       |       |/|                |       |/|               ║
 ║    `-------+-------+-------' |                `-------+ |               ║
 ║            |       |       | |                        | |               ║
 ║            |       |       |/|                .-------+ |               ║
 ║            +-------+-------+ |               /       /| |               ║
 ║            |       |       | |              +-------+ |/|               ║
 ║            |       |       |/               |       |/| |               ║
 ║            `-------+-------'                +-------+ |/                ║
 ║                                             |       |/                  ║
 ║                                             `-------'                   ║
 ║                                                                         ║
 ║     [■■■■] Axé Gold (#EBB434)     |     [■■■■] Maré Teal (#00D2D3)      ║
 ║                                                                         ║
 ║                 Press [Enter] or Ctrl+C to resume session               ║
 ╚═════════════════════════════════════════════════════════════════════════╝
EOF
  printf "\033[0m"
  read -r _
fi
