#!/bin/bash

# Constants


IFS="*"
PLAYLIST_DIR=".config/mpd/playlists/"

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


playsongs ()
{
	mpc clear
	mpc searchadd artist "$1" album "$2" title "$3"
	
	if [[ $4 == TRUE ]]; then
		mpc shuffle
	fi
	
	mpc play
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
CURRENT_STATE=$(mpc status "%state%")
CURRENT_POS=$(mpc playlist | grep -n -m1 $(mpc current) | sed 's/\([0-9]*\).*/\1/')
QUEUE_LENGTH=$(mpc playlist | grep -c "^")


if [[ ${#CURRENT_SONG} -gt 0 ]]; then
	echo -e "\0message\x1fCurrent: ($CURRENT_STATE) $CURRENT_SONG ($CURRENT_POS/$QUEUE_LENGTH)"
fi

case ${INFO[0]} in
	
	"" | "main")
		item "Play/Pause" 	main 	"mpc toggle"
		item "Next" 		main 	"mpc next"
		item "Previous" 	main 	"mpc cdprev"
		item "Manage Queue" 	queue
		item "Library"		artist_list
		item "Playlists"	playlists
		item "Options"		options
		item "Command"		cmd
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
		item "Play Now"			queue	"mpc play ${INFO[5]}"
		item "View In Library"		queue_song 	
		;;
	"artist_list")
		message "> /"
		item ".."	main
		item "*"	album_list	""
		mpc list artist	|\
			awk -v d="$IFS" '{printf "%s\0info\x1falbum_list%s%s%s\n", $0, d, d, $0}'
		;;
	"album_list") # artist
		ARTIST="*"
		if [[ ${INFO[2]} != "" ]]; then
			ARTIST=${INFO[2]}
		fi
		message "> /$ARTIST/"
		item ".."	artist_list
		item "*"	song_list	""	"${INFO[2]}"
		if [[ ${INFO[2]} == "" ]]; then
			mpc list album |\
				awk -v a=${INFO[2]} -v d="$IFS" '{ printf "%s\0info\x1fsong_list%s%s%s%s%s\n", $0, d, d, a, d, $0 }'
		else
			mpc list album artist "${INFO[2]}" |\
				awk -v a=${INFO[2]} -v d="$IFS" '{ printf "%s\0info\x1fsong_list%s%s%s%s%s\n", $0, d, d, a, d, $0 }'
		fi
		;;
	"song_list")
		ARTIST="*"
		if [[ ${INFO[2]} != "" ]]; then
			ARTIST=${INFO[2]}
		fi
		ALBUM="*"
		if [[ ${INFO[3]} != "" ]]; then
			ALBUM=${INFO[3]}
		fi
		message "> /$ARTIST/$ALBUM/"
		item ".."	album_list	"" 	"${INFO[2]}"
		item "*"	song_actions	""	"${INFO[2]}" "${INFO[3]}"
		mpc -f "%artist% - %title%\\song_actions${IFS}${IFS}%artist%${IFS}%album%${IFS}%title%" search artist "${INFO[2]}" album "${INFO[3]}" |\
			awk -F\\ -v d="$IFS" '{ printf "%s\0info\x1f%s\n", $1, $2 }'
		;;
	"song_actions")
		ARTIST="*"
		if [[ ${INFO[2]} != "" ]]; then
			ARTIST=${INFO[2]}
		fi
		ALBUM="*"
		if [[ ${INFO[3]} != "" ]]; then
			ALBUM=${INFO[3]}
		fi
		TITLE="*"
		if [[ ${INFO[4]} != "" ]]; then
			TITLE=${INFO[4]}
		fi
		message "> /$ARTIST/$ALBUM/$TITLE ($(mpc search artist "${INFO[2]}" album "${INFO[3]}" title "${INFO[4]}" | grep -c "^") songs)"
		item ".."		song_list	""	"${INFO[2]}" "${INFO[3]}"
		item "Play"		song_actions	"playsongs \"${INFO[2]}\" \"${INFO[3]}\" \"${INFO[4]}\""		${INFO[2]} ${INFO[3]} ${INFO[4]}
		item "Shuffle"		song_actions	"playsongs \"${INFO[2]}\" \"${INFO[3]}\" \"${INFO[4]}\" TRUE"		${INFO[2]} ${INFO[3]} ${INFO[4]}	
		item "Append to Queue"	song_actions	"mpc searchadd artist \"${INFO[2]}\" album \"${INFO[3]}\" title \"${INFO[4]}\""	${INFO[2]} ${INFO[3]} ${INFO[4]}
		item "Append to Playlist"	song_actions	""
		;;
	"playlists")
		item ".."	main
		mpc lsplaylists |\
			awk -v d="$IFS" '{printf "%s\0info\x1fplaylist_songs%s%s%s", $0, d, d, $0}'
		;;
	"playlist_songs")
		item ".."	playlists
		mpc playlist "${INFO[2]}"
		;;
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
		item "Update Database"		options	"mpc rescan --wait"
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
	"*")
		message "ERROR: Unknown menu \"${INFO[0]}\""
		item "Main Menu"	menu
		echo "Debug:"
		echo $ROFI_INFO
		;;
esac
