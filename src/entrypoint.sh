#!/bin/bash

# Copyright (c) DockForge <dockforge@gmail.com>. All rights reserved.
# https://github.com/DockForge/packages
#
# Licensed under the GNU General Public License v3.0.

# Fail script on any error
set -e

# Output file path
OUTPUT_FILE="/workspace/packages.txt"

# Function to append output to file
function append_to_file {
    printf "%-45s %-45s %-10s\n" "$1" "$2" "$3" >> $OUTPUT_FILE
}

# Clear the output file
> $OUTPUT_FILE

# Print header
append_to_file "NAME" "VERSION" "TYPE"

# Capture APT packages if available
echo "Checking APT packages..."
if command -v dpkg-query &> /dev/null; then
    dpkg-query -W -f='${binary:Package} ${Version}\n' | while read -r line; do
        echo "APT: $line"  # Debugging: Print each APT package
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "apt"
    done
else
    echo "dpkg-query not found"
fi

# Capture APK packages if available
echo "Checking APK packages..."
if command -v apk &> /dev/null; then
    apk info -vv | awk -F ' - ' '{print $1, $2}' | while read -r name version; do
        echo "APK: $name $version"  # Debugging: Print each APK package
        append_to_file "$name" "$version" "apk"
    done
else
    echo "apk not found"
fi

# Capture RPM packages if available
echo "Checking RPM packages..."
if command -v rpm &> /dev/null; then
    rpm -qa --qf '%{NAME} %{VERSION}\n' | sort -u | while read -r line; do
        echo "RPM: $line"  # Debugging: Print each RPM package
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "rpm"
    done
else
    echo "rpm not found"
fi

# Capture Python packages (system-wide)
echo "Checking Python packages..."
if command -v pip3 &> /dev/null; then
    pip3 list --format=freeze | while read -r line; do
        package=$(echo $line | awk -F '==' '{print $1}')
        version=$(echo $line | awk -F '==' '{print $2}')
        echo "Python: $package $version"  # Debugging: Print each Python package
        append_to_file "$package" "$version" "python"
    done
else
    echo "pip3 not found"
fi

# Capture Node.js packages (global)
echo "Checking Node.js packages..."
if command -v npm &> /dev/null; then
    npm ls -g --depth=0 --json | jq -r '.dependencies | to_entries[] | "\(.key) \(.value.version)"' | while read -r line; do
        echo "Node.js: $line"  # Debugging: Print each Node.js package
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "npm"
    done
else
    echo "npm not found"
fi

# Capture Ruby gems
echo "Checking Ruby gems..."
if command -v gem &> /dev/null; then
    gem list | while read -r line; do
        package=$(echo $line | awk '{print $1}')
        version=$(echo $line | awk '{print $2}' | tr -d '()')
        echo "Ruby: $package $version"  # Debugging: Print each Ruby package
        append_to_file "$package" "$version" "gem"
    done
else
    echo "gem not found"
fi

# Capture PHP Composer packages
echo "Checking PHP Composer packages..."
if command -v composer &> /dev/null; then
    composer global show --format=json | jq -r '.installed[] | "\(.name) \(.version)"' | while read -r line; do
        echo "Composer: $line"  # Debugging: Print each Composer package
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "composer"
    done
else
    echo "composer not found"
fi

# Output the captured versions to the console (optional)
cat $OUTPUT_FILE