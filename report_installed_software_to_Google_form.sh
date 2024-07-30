#!/bin/bash

# Define the log directory and file paths
LOG_DIR="$HOME/Library/Logs/SoftwareInstalls"
INSTALLED_SOFTWARE_FILE="$LOG_DIR/installedSoftware.csv"
PREVIOUSLY_INSTALLED_SOFTWARE_FILE="$LOG_DIR/previouslyInstalledSoftware.csv"
RECENTLY_INSTALLED_SOFTWARE_FILE="$LOG_DIR/recentlyInstalledSoftware.csv"
LOG_FILE="$LOG_DIR/log.txt"

# Collect username and computer name
USER_NAME=$(whoami)
COMPUTER_NAME=$(scutil --get ComputerName)

# Create the log directory if it does not exist
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    echo "Created directory: $LOG_DIR"
fi

# Create the log.txt file if it does not exist
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    echo "Created file: $LOG_FILE"
fi

# Check if the installedSoftware.csv file exists
if [ -f "$INSTALLED_SOFTWARE_FILE" ]; then
    # Rename it to previouslyInstalledSoftware.csv
    mv "$INSTALLED_SOFTWARE_FILE" "$PREVIOUSLY_INSTALLED_SOFTWARE_FILE"
    echo "Renamed $INSTALLED_SOFTWARE_FILE to $PREVIOUSLY_INSTALLED_SOFTWARE_FILE"
else
    # Create an empty installedSoftware.csv file
    echo "Name,Publisher,Version,Installation Date,User Name,Computer Name" > "$INSTALLED_SOFTWARE_FILE"
    echo "Created file: $INSTALLED_SOFTWARE_FILE"
fi

# Function to extract software information
get_software_info() {
    local app_path="$1"
    local app_name=$(basename "$app_path" .app)
    local app_info=$(mdls -name kMDItemVersion -name kMDItemDisplayName -name kMDItemContentCreationDate "$app_path")
    local app_publisher=$(codesign -dvv "$app_path" 2>&1 | grep -o "Authority=.*" | head -n 1 | sed 's/Authority=//' | sed 's/Developer ID Application: //')
    local app_version=$(echo "$app_info" | grep kMDItemVersion | awk -F'=' '{print $2}' | xargs)
    local app_date=$(echo "$app_info" | grep kMDItemContentCreationDate | awk -F'=' '{print $2}' | xargs | cut -d' ' -f1)
    
    # Default to 'Unknown' if no information found
    app_publisher=${app_publisher:-Unknown}
    app_version=${app_version:-Unknown}
    app_date=${app_date:-Unknown}

    echo "$app_name,$app_publisher,$app_version,$app_date,$USER_NAME,$COMPUTER_NAME"
}

# List all installed software and add it to the installedSoftware.csv file
echo "Name,Publisher,Version,Installation Date,User Name,Computer Name" > "$INSTALLED_SOFTWARE_FILE"
for app in /Applications/*; do
    if [ -d "$app" ]; then
        get_software_info "$app" >> "$INSTALLED_SOFTWARE_FILE"
    fi
done
echo "Listed installed software in $INSTALLED_SOFTWARE_FILE"

# Function to submit data to Google Form
submit_to_google_form() {
    local app_name="$1"
    local app_publisher="$2"
    local app_version="$3"
    local app_date="$4"
    
    curl -s -X POST -d "entry.ENTERIDHERE=$COMPUTER_NAME" \
                   -d "entry.ENTERIDHERE=$USER_NAME" \
                   -d "entry.ENTERIDHERE=$app_publisher" \
                   -d "entry.ENTERIDHERE=$app_name" \
                   -d "entry.ENTERIDHERE=$app_version" \
                   -d "entry.ENTERIDHERE=$app_date" \
                   "https://docs.google.com/forms/d/e/ENTERIDHERE/formResponse"
}

# Compare files if both exist
if [ -f "$INSTALLED_SOFTWARE_FILE" ] && [ -f "$PREVIOUSLY_INSTALLED_SOFTWARE_FILE" ]; then
    # Create or overwrite the recentlyInstalledSoftware.csv file
    echo "Name,Publisher,Version,Installation Date,User Name,Computer Name" > "$RECENTLY_INSTALLED_SOFTWARE_FILE"
    
    # Compare and add new software entries
    grep -F -x -v -f <(tail -n +2 "$PREVIOUSLY_INSTALLED_SOFTWARE_FILE") <(tail -n +2 "$INSTALLED_SOFTWARE_FILE") | while IFS=, read -r app_name app_publisher app_version app_date user_name computer_name; do
        echo "$app_name,$app_publisher,$app_version,$app_date,$USER_NAME,$COMPUTER_NAME" >> "$RECENTLY_INSTALLED_SOFTWARE_FILE"
        echo "$app_name,$app_publisher,$app_version,$app_date,$USER_NAME,$COMPUTER_NAME" >> "$LOG_FILE"
        submit_to_google_form "$app_name" "$app_publisher" "$app_version" "$app_date"
    done

    echo "Created/updated $RECENTLY_INSTALLED_SOFTWARE_FILE with new software installations"
fi

echo "Script execution completed."
