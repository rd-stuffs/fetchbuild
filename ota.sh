#!/bin/bash

# Ensure at least one argument is provided
[ -z "$1" ] && { echo "Please provide at least one argument (OTA device codename)!"; exit 1; }

# Loop through each device name provided as arguments
for device_name in "$@"; do
  # Extract Android version from the device name
  android_version=$(echo "$device_name" | grep -oP '\K\d+')
  [[ $android_version -ge 14 && $android_version -le 16 ]] || echo "Android version isn't between 14 and 16, trying anyway…"

  # Default to Android version 15 if not set
  android_version="${android_version:-15}"

  # Remove any non-alphabetic characters from the device name
  device_name=${device_name//[^[:alpha:]_]/}

  # Determine the URL source based on whether the device is a beta
  if [[ $device_name == *_beta* ]]; then
    last_build_url=$(curl -b "devsite_wall_acks=nexus-ota-tos" -Ls "https://developer.android.com/about/versions/$android_version/download-ota?partial=1" \
      | grep -oP "https://\S+${device_name}\S+\.zip" | tail -1)
  else
    last_build_url=$(curl -b "devsite_wall_acks=nexus-ota-tos" -Ls 'https://developers.google.com/android/ota?partial=1' \
      | grep -oP "\d+(\.\d+)+ \([^)]+\).*?https://\S+${device_name}\S+zip" \
      | sed -n 's/\\u003c\/td\\u003e\\n    \\u003ctd\\u003e\\u003ca href=\\"/ /p' \
      | awk -F',' 'NF<=2' | tail -1 | grep -Eo "(https\S+)")
  fi

  # Print the URL and run the Dart script if found
  if [[ -n $last_build_url ]]; then
    echo "Last build URL for ${device_name^}: $last_build_url"
    dart run bin/fetchbuild.dart "$last_build_url"
  else
    echo "No build found for ${device_name^}"
  fi
done
