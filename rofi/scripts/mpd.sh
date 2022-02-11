#!/bin/bash

# Constants

IFS="*"

# Functions

message ()
{
	echo -e "\0message\x1f$1"
}

item ()
{
	echo -e "$1\0info\x1f$(shift 1; echo "$*")"
}

prompt ()
{
	echo -e "\0prompt\x1f$1"
}

query ()
{
	echo -e "\0prompt\x1f$1"
	echo -e "\0no-custom\x1ffalse"
	echo -e "\0custom-info\x1f$(shift 1; echo "$*")"
}

# Main

# Setup default mode options
echo -e "\0markup-rows\x1ftrue"
echo -e "\0no-custom\x1ftrue"
echo -e "\0prompt\x1fmpd-rofi"
echo -e "\0message\x1f"

read -r -a INFO <<< $ROFI_INFO

if [[ ${#INFO[@]} -gt 1 ]]; then
	eval ${INFO[1]} > /dev/null
fi

CURRENT_SONG=$(mpc current -f "%artist% - %title%")

if [[ ${#CURRENT_SONG} -gt 0 ]]; then
	echo -e "\0message\x1fCurrent: $CURRENT_SONG"
fi

case ${INFO[0]} in
	
	"" | "main")
		item "Play/Pause" 	main 	"mpc toggle"
		item "Next" 		main 	"mpc next"
		item "Previous" 	main 	"mpc cdprev"
		item "Manage Queue" 	queue
		item "Library"		library
		item "Options"		options
		item "cmd"		cmd
		;;
	"queue")
		item ".."		main
		item "Clear"		queue	"mpc clear"
		item "Shuffle" 		queue	"mpc shuffle"		
		item "Save As Playlist" queue_saveas	
		mpc -f "%artist% - %title%\\queue_song$IFS$IFS%artist%$IFS%album%$IFS%title%" playlist |\
		       awk -F\\ -v ifs="$IFS" '{ printf "%s\0info\x1f%s%s%s\n", $1, $2, ifs, NR}'
		;;
	"queue_saveas")
		query 	"playlist name"	queue	"mpc save \"\$1\""
		item	"Cancel"	queue	
		;;
	"queue_song")
		message "Song: ${INFO[2]} - ${INFO[4]}"
		item ".."			queue
		item "Remove From Queue"	queue	"mpc del ${INFO[5]}"
		item "Play Now"			queue	"mpc move ${INFO[5]} 1"
		;;
	"library")
		item ".."		main
		item "Artists"		lib_artists
		item "Albums"		lib_albums
		item "Songs"		lib_songs
		item "Playlists"	playls
		;;
	"lib_artists")
		item ".."		library
		mpc list artist |\
			awk -v ifs="$IFS" '{ printf "%s\0info\x1flib_artist_albums%s%s%s\n", $0, ifs, ifs, $0 }'
		;;
	"lib_artist_albums")
		item ".."		lib_artists
		mpc list album artist "${INFO[2]}" |\
			awk -v ifs="$IFS" artist="${INFO[2]}" '{ printf "%s\0info\x1flib_artist_album_songs%s%s%s%s%s", $0, ifs, ifs, artist, ifs, $0 }'
		;;
	"lib_artist_album_songs")
		item ".."		lib_artist_albums	""	"${INFO[2]}"
		mpc find artist "${INFO[2]}" album "${INFO[3]}" |
	"lib_song")
		message "Song: ${INFO[2]} - ${INFO[4]}"
		item ".."		${INFO[2]}	
	"options")
		item ".."		main
		
		STATUS="$(mpc status)"
		
		CONSUME=$(echo "$STATUS" | grep -c "consume: on")
		if [[ $CONSUME -gt 0 ]]; then
			item "Consume: On"	options	"mpc consume off"
		else
			item "Consume: Off"	options "mpc consume on"
		fi

		CROSSFADE="$(mpc crossfade | awk '{print $2}')"
		item "Crossfade: $CROSSFADE s" crossfade
		
		CONSUME=$(echo "$STATUS" | grep -c "random: on")
		if [[ $CONSUME -gt 0 ]]; then
			item "Random: On"	options	"mpc random off"
		else
			item "Random: Off"	options "mpc random on"
		fi
	
		CONSUME=$(echo "$STATUS" | grep -c "repeat: on")
		if [[ $CONSUME -gt 0 ]]; then
			item "Repeat: On"	options	"mpc repeat off"
		else
			item "Repeat: Off"	options "mpc repeat on"
		fi
		;;
	"crossfade")
		CROSSFADE="$(mpc crossfade | awk '{print $2}')"
		message "Crossfade: $CROSSFADE s"
		item ".."		options	
		item "Set To 0 s"	crossfade	"mpc crossfade 0"
		item "+1 s"		crossfade	"mpc crossfade $(( $CROSSFADE + 1))"
		item "-1 s"		crossfade	"mpc crossfade $(( $CROSSFADE - 1))"
		;;
	"cmd")
		message "Enter a command to execute."
		query "cmd"		cmd_out		"exec-input"
		item "Cancel"		main
		;;
	"cmd_out")
		item "Done"		main
		echo -e "Command Output:\n$(eval $1)" | awk '{print $0, "\0nonselectable\x1ftrue"}'
		;;
esac
