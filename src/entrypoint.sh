#!/bin/bash

# Copyright (c) DockForge <dockforge@gmail.com>. All rights reserved.
# https://github.com/DockForge/packages
#
# Licensed under the GNU General Public License v3.0.

# Fail script on any error
set -e

# Output file path
OUTPUT_FILE="/workspace/package_versions.txt"

# Function to append output to file
function append_to_file {
    printf "%-40s %-20s %-10s\n" "$1" "$2" "$3" >> $OUTPUT_FILE
}

# Clear the output file
> $OUTPUT_FILE

# Print header
append_to_file "NAME" "VERSION" "TYPE"

# Capture APT packages if available
if [ -f /var/lib/dpkg/status ]; then
    chroot . dpkg-query -W -f='${binary:Package} ${Version}\n' | while read -r line; do
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "apt"
    done
fi

# Capture APK packages if available
if [ -f /lib/apk/db/installed ]; then
    chroot . apk info -vv | while read -r line; do
        append_to_file "$(echo $line | awk -F '-' '{print $1}')" "$(echo $line | awk -F '-' '{print $2}')" "apk"
    done
fi

# Capture RPM packages if available
if [ -f /var/lib/rpm/Packages ]; then
    chroot . rpm -qa --qf '%{NAME} %{VERSION}\n' | while read -r line; do
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "rpm"
    done
fi

# Capture Python packages (system-wide)
if [ -d /usr/lib/python*/site-packages ]; then
    chroot . pip3 list --format=freeze | while read -r line; do
        package=$(echo $line | awk -F '==' '{print $1}')
        version=$(echo $line | awk -F '==' '{print $2}')
        append_to_file "$package" "$version" "python"
    done
fi

# Capture Node.js packages (global)
if [ -d /usr/lib/node_modules ]; then
    chroot . npm ls -g --depth=0 --json | jq -r '.dependencies | to_entries[] | "\(.key) \(.value.version)"' | while read -r line; do
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "npm"
    done
fi

# Capture Ruby gems
if [ -d /var/lib/gems ]; then
    chroot . gem list | while read -r line; do
        package=$(echo $line | awk '{print $1}')
        version=$(echo $line | awk '{print $2}' | tr -d '()')
        append_to_file "$package" "$version" "gem"
    done
fi

# Capture PHP Composer packages
if [ -f /usr/local/bin/composer ]; then
    chroot . composer global show --format=json | jq -r '.installed[] | "\(.name) \(.version)"' | while read -r line; do
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "composer"
    done
fi

# Output the captured versions to the console (optional)
cat $OUTPUT_FILE