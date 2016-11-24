#!/bin/sh

# Generate Bing wallpaper downloader and add to launchAgant service

# Usage: sh bing-wallpaper.sh [-u url] [-o dest_dir] [-r target_resolution]

usage() {
	echo "Usage: \n\t$0 [-u bing-url] [-o dest_dir] [-r target_resolution]"
	echo "Example:\n\t$0 -o ~/Pictures/wallpaper/ -r 1920x1080 -u http://cn.bing.com"
}

while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help|?)
			usage $0
			exit 0
			;;
		-u)
			URL=$2
			shift 2
			;;
		-o)
			DEST_DIR=$2
			shift 2
			;;
		-r)
			RESOLUTION=$2
			shift 2
			;;
		*)
			echo "Unknown argument"
			usage $0
			exit 1
			;;
	esac
done

if [[ -z "$URL" ]]; then
	URL="http://www.bing.com"
fi

if [[ -z "$DEST_DIR" ]]; then
	DEST_DIR="$HOME/Pictures"
	if [[ -d $DEST_DIR ]]; then
		DEST_DIR=$DEST_DIR/bing-wallpapers
	fi
fi


if [[ -z "$RESOLUTION" ]]; then
	RESOLUTION="1920x1080"
fi

mkdir -p "$DEST_DIR"
DEST_DIR=$(cd $DEST_DIR; pwd)

EXE_FILE="$DEST_DIR/bing-wallpaper.sh"
AUTO_RUN_PLIST="$HOME/Library/LaunchAgents/bing-wallpaper-auto-update.plist"

##################

echo "DEST_DIR: $DEST_DIR"
echo "URL: $URL"
echo "RESOLUTION: $RESOLUTION"
echo "EXE_FILE: $EXE_FILE"
echo "AUTO_RUN_PLIST: $AUTO_RUN_PLIST"


#output downloader file
cat <<EOF > "$EXE_FILE"
#!/usr/bin/env bash

WALLPAPER_DIR="$DEST_DIR"
BING_URL="$URL"
TARGET_RESOLUTION="$RESOLUTION" #target resolution is 1920x1080

UA="User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36"

mkdir -p "\$WALLPAPER_DIR"

download_image() {
	url=\$1
	out_file=\$2

	[ -s "\$out_file" ] || rm -f "\$out_file"

	if [ ! -f "\$out_file" ]; then
        echo "Downloading: \$out_file ..."
        curl -Lo "\$out_file" "\$url" -H "\$UA" -H "Referer: \$BING_URL"
        [ -s  "\$out_file" ] || rm -f "\$out_file"
    fi
}

urls=( \$(curl -sL "\$BING_URL" | \\
    grep -Eo "url:\s*['\"].*?['\"]"| \\
    sed -e "s/url: *//"|\\
    sed -e "s/['\"]//g") )


for p in \${urls[@]}; do

	([[ \$p = http://* ]] || [[ \$p = https://* ]])  || p="\$BING_URL/\$p"
	
    filename=\$(echo \$p|sed -e "s/.*\/\(.*\)/\1/")
    if [ "\$filename" != "" ]; then

    	if [ ! -z "\$TARGET_RESOLUTION" ]; then
    		target_name=\$(echo \$filename|sed -e "s/_[0-9]\{1,\}x[0-9]\{1,\}./_\$TARGET_RESOLUTION./")
    		url=\$(echo \$p|sed -e "s/\$filename/\$target_name/")

    		out_file=\$WALLPAPER_DIR/\$target_name
    		download_image \$url "\$out_file"
    	fi

    	if [ ! -f "\$out_file" ]; then
    		out_file=\$WALLPAPER_DIR/\$filename
    		download_image \$p "\$out_file"
    	fi

    	if [ -f "\$out_file" -a -z "\$set_today" ]; then
    		today=\$WALLPAPER_DIR/"today.jpg"
    		rm -f \$today
    		ln -s "\$out_file" \$today

    		[ -f \$today ] && set_today=1
    	fi
    fi
done

echo "Done!"   
EOF

[ -f $EXE_FILE ] || exit "\033[31m;Can not create executable file: $EXE_FILE\033[0m;"

chmod u+x "$EXE_FILE"

# Output auto execute plist file
LaunchAgentsPath=$(dirname $AUTO_RUN_PLIST)
mkdir -p $LaunchAgentsPath

cat <<EOF > "$AUTO_RUN_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>bing-wallpaper-auto-update</string>
		<key>ProgramArguments</key>
		<array>
			<string>/bin/bash</string>
			<string>$EXE_FILE</string>
		</array>
		<key>LowPriorityIO</key>
		<true/>
		<key>Nice</key>
		<integer>1</integer>
		<key>KeepAlive</key>
        <false/>
       	<key>RunAtLoad</key>
        <true/>
        <key>StartInterval</key>
        <integer>3600</integer>
	</dict>
</plist>
EOF

if [ ! -f $AUTO_RUN_PLIST ]; then
	echo "\033[31mCan not create auto update config file: $AUTO_RUN_PLIST\033[0m"
	exit 1
fi

launchctl unload $AUTO_RUN_PLIST
launchctl load $AUTO_RUN_PLIST
launchctl start $AUTO_RUN_PLIST

echo "\033[1;32mDone!\033[0m"







