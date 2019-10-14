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

EXE_FILE="$DEST_DIR/bin/bing-wallpaper.sh"
AUTO_RUN_PLIST="$HOME/Library/LaunchAgents/bing-wallpaper-auto-update.plist"
mkdir -p "$DEST_DIR/bin"

##################

echo "DEST_DIR: $DEST_DIR"
echo "URL: $URL"
echo "RESOLUTION: $RESOLUTION"
echo "EXE_FILE: $EXE_FILE"
echo "AUTO_RUN_PLIST: $AUTO_RUN_PLIST"


#output downloader file
cat <<EOF > "$EXE_FILE"
#!/usr/bin/env bash

download_image() {
	url=\$1
	out_file=\$2

	[ -s "\$out_file" ] || rm -f "\$out_file"

	if [ ! -f "\$out_file" ]; then
        echo "Downloading: \$out_file ..."
        curl -Lo "\$out_file" "\$url"
        [ -s  "\$out_file" ] || rm -f "\$out_file"

        if [ -f "\$out_file" ]; then 
            is_img_file=\$(file "\$out_file" | grep -e " image data" | wc -l)
            echo \$is_img_file
            [ \$is_img_file -gt 0 ] || rm -f "\$out_file"
        fi
    fi
}

WALLPAPER_SERVER="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1"
WALLPAPER_DIR="\$HOME/Pictures/bing-wallpapers"

data=\$(curl -sL "\$WALLPAPER_SERVER")
pic_url=\$(echo "\$data" | grep -Eo "\"url\":\s*['\"].*?['\"]" | sed -e "s/\"url\"[\: ]\+//"| sed -e "s/['\"]//g")
pic_url=\$(echo "\$pic_url" | sed -e "s/url:\(.*\)/\1/")
[ "\$pic_url" != "" ] || ( echo "invalid pic url" && exit )
full_pic_url="https://www.bing.com\$pic_url"

file_name=\$(echo "\$pic_url" | grep -Eo ".*\bid=.*\&")
file_name=\$(echo "\$file_name" | sed -e "s/.*id=\(.*\)\&/\1/")
file_name=\$(echo "\$file_name" | awk -F '&' '{print \$1}')
if [[ "\$file_name" == "" ]]; then
    file_name=\$(IFS='/' read -r -a array <<< "\$pic_url"; echo "\${array[@]: -1:1}")
fi
[ "\$file_name" != "" ] || file_name=\$(date "+%Y-%m-%d.jpg")
out_file="\$WALLPAPER_DIR"/"\$file_name"

echo \$out_file
echo \$full_pic_url


if [[ ! -f "\$out_file" ]]; then
	download_image "\$full_pic_url" "\$out_file"
fi
 
EOF

[ -f $EXE_FILE ] || exit "\033[31m;Can not create executable file: $EXE_FILE\033[0m;"

chmod u+x "$EXE_FILE"

# # Output auto execute plist file
# LaunchAgentsPath=$(dirname $AUTO_RUN_PLIST)
# mkdir -p $LaunchAgentsPath

# cat <<EOF > "$AUTO_RUN_PLIST"
# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
# <plist version="1.0">
# 	<dict>
# 		<key>Label</key>
# 		<string>bing-wallpaper-auto-update</string>
# 		<key>ProgramArguments</key>
# 		<array>
# 			<string>/bin/bash</string>
# 			<string>$EXE_FILE</string>
# 		</array>
# 		<key>LowPriorityIO</key>
# 		<true/>
# 		<key>Nice</key>
# 		<integer>1</integer>
# 		<key>KeepAlive</key>
#         <false/>
#        	<key>RunAtLoad</key>
#         <true/>
#         <key>StartInterval</key>
#         <integer>7200</integer>
# 	</dict>
# </plist>
# EOF

# if [ ! -f $AUTO_RUN_PLIST ]; then
# 	echo "\033[31mCan not create auto update config file: $AUTO_RUN_PLIST\033[0m"
# 	exit 1
# fi

# launchctl unload $AUTO_RUN_PLIST
# launchctl load $AUTO_RUN_PLIST
# launchctl start $AUTO_RUN_PLIST

echo "\033[1;32mDone!\033[0m"







