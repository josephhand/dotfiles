
function fish_greeting

	echo

	set -l TEXT (fortune definitions -sn300 | cowsay -W(math -s0 $COLUMNS / 2) | string split0)

	set -l WIDTH (echo $TEXT | wc -L)
	set -l INDENT (math -s0 $COLUMNS / 2 - $WIDTH / 2)
	
	echo $TEXT | pr -to $INDENT
end
