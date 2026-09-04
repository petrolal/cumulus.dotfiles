#!/usr/bin/env bash

## Spotify script for waybar --------------------------------

spotify_status=$(playerctl -p spotify_player status 2>/dev/null)
md_cmd="playerctl -p spotify_player metadata"

if [[ "$spotify_status" = "Playing" ]]; then
	if [[ "$($md_cmd title)" == "Advertisement" ]]; then
		echo -e " Stupid Ads!"
	else
		echo -e " $($md_cmd artist) - $($md_cmd title)\nPlaying: $($md_cmd artist) - $($md_cmd title)\nplaying"
	fi
elif [[ "$spotify_status" = "Paused" ]]; then
	echo -e " $($md_cmd artist) - $($md_cmd title)\nPaused: $($md_cmd artist) - $($md_cmd title)\npaused"
else
	echo -e "󰎊 Spotify Offline!\nSpotify Offline.\noffline"
fi
