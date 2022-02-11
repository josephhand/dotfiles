#/bin/bash

echo -e "\0no-custom\x1ftrue"

DEVICE_INFO=$(bluetoothctl info)

DEVICE_CONNECTION=$(echo "$DEVICE_INFO" | grep -c "Connected: yes")
DEVICE_NAME=$(echo "$DEVICE_INFO" | grep "Name: " | cut -d ' ' -f2-)
DEVICE_MAC=$(echo "$DEVICE_INFO" | grep "^Device" | awk '{ print $2 }')

echo -en "\0message\x1f\n"

if [[ ${#DEVICE_NAME} -gt 0 && $DEVICE_CONNECTION -gt 0 ]] ; then
	echo -en "\0message\x1fConnected: $DEVICE_NAME\n"
fi

case $1 in
	"" | "..")
		echo "Connect"
		echo "Disconnect"
		echo "Pair"
		echo "Unpair"
		echo "Trust"
		;;
	"Connect")
		echo ..
		bluetoothctl paired-devices |\
			cut -d ' ' -f2- |\
			awk '{print $0, "\0info\x1fconnect"}'
		;;
	"Disconnect")
		echo ..
		bluetoothctl paired-devices |\
			cut -d ' ' -f2- |\
			awk '{print $0, "\0info\x1fdisconnect"}'
		;;
	"Pair" | "Refresh")
		coproc( bluetoothctl scan on )
		echo -e "\0message\x1fScanning..."
		echo ".."
		echo Refresh
		bluetoothctl devices |\
			cut -d ' ' -f2- |\
			awk '{print $0, "\0info\x1fpair"}'
		;;
	"Unpair")
		echo ".."
		bluetoothctl paired-devices |\
			cut -d ' ' -f2- |\
			awk '{print $0, "\0info\x1fremove"}'
		;;
	"Trust")
		echo ".."
		bluetoothctl paired-devices |\
			cut -d ' ' -f2- |\
			awk '{print $0, "\0info\x1ftrust"}'
		;;
	*)
		coproc( bluetoothctl $ROFI_INFO "$( echo $1 | awk '{print $1}' )" )
		;;
esac
