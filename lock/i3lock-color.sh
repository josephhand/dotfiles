#!/bin/bash

INSTANCES=$(pgrep i3lock | grep -c "^")

#echo Instances: $INSTANCES

if [[ $INSTANCES -lt 3 ]] ; then

IMAGE=$(mktemp --suffix=.png)

echo $IMAGE

scrot -oF $IMAGE

#import -silent -window root $IMAGE 

magick $IMAGE \
	-level "0%,3200%,2.0" -filter Gaussian -resize 20% -define "filter:sigma=3" -resize 500.5% \
	-font "/usr/share/fonts/TTF/Sauce Code Pro Nerd Font Complete Mono.ttf" -pointsize 26 -fill "#c5ced9" -gravity center \
	-annotate +0+160 "Type Password To Unlock" \
	-pointsize 17 \
	-annotate +0+200 "\"$(fortune platitudes paradoxum -sn50)\"" \
	".config/lock/lock.png" -composite \
	$IMAGE

i3lock -n -i "$IMAGE" \
	--indicator --radius=70 --ring-width=2 \
	--inside-color=00000000 --ring-color=181d2600 \
	--insidever-color=00000000 --ringver-color=8c99e5ff \
	--insidewrong-color=00000000 --ringwrong-color=e58c9eff \
	--line-uses-ring \
	--keyhl-color=c5ced9ff --bshl-color=e58c9eff --separator-color=00000000 \
	--verif-text='' --wrong-text='' --noinput-text='' \
	--force-clock --{time,date}-color=c5ced9 \
	--time-str="%H:%M:%S" --date-str="%y-%m-%d" \
	--{time,date}-font="SauceCodePro Nerd Font" \
	--time-size=26 --date-size=17 \
	--time-pos="x+w/2:y+h/2-160" --date-pos="tx:ty-40" \
	--pass-{media,power}
#	--no-verify

fi

#i3lock -n --blur=10 --greeter-text="Type Password To Unlock\n\n$(fortune platitudes paradoxum -sn50)" --greeter-color=ffffffff --indicator --radius=60 --ring-width=5
