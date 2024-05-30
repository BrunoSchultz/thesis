#!/bin/bash
########################

# Get the current working directory
cwd=$(pwd)

# Define the directory where log files are stored
log_dir="$cwd/data/log"

# Find log files containing the keywords failed or error
failed_logs=$(grep -ilE 'failed|error' "$log_dir"/*)

# Print log files with the keywords
if [ -n "$failed_logs" ]; then
    echo "The following files have disappointed you:"
    for file in $failed_logs; do
        echo
        echo "File: $file"
        grep --color -iE 'failed|error' "$file"
    done
else
    echo "All is good in the world."
fi