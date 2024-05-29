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

# Capture APT packages
dpkg-query -W -f='${binary:Package} ${Version}\n' | while read -r line; do
    append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "apt"
done

# Capture Python packages (system-wide)
if command -v pip3 &> /dev/null; then
    pip3 list --format=freeze | while read -r line; do
        package=$(echo $line | awk -F '==' '{print $1}')
        version=$(echo $line | awk -F '==' '{print $2}')
        append_to_file "$package" "$version" "python"
    done
fi

# Capture Node.js packages (global)
if command -v npm &> /dev/null; then
    npm ls -g --depth=0 --json | jq -r '.dependencies | to_entries[] | "\(.key) \(.value.version)"' | while read -r line; do
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "npm"
    done
fi

# Capture Ruby gems
if command -v gem &> /dev/null; then
    gem list | while read -r line; do
        package=$(echo $line | awk '{print $1}')
        version=$(echo $line | awk '{print $2}' | tr -d '()')
        append_to_file "$package" "$version" "gem"
    done
fi

# Capture PHP Composer packages
if command -v composer &> /dev/null; then
    composer global show --format=json | jq -r '.installed[] | "\(.name) \(.version)"' | while read -r line; do
        append_to_file "$(echo $line | awk '{print $1}')" "$(echo $line | awk '{print $2}')" "composer"
    done
fi

# Output the captured versions to the console (optional)
cat $OUTPUT_FILE

# Commit and push the package_versions.txt file
cd /workspace
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git add package_versions.txt
git commit -m "Add package versions report"
git push