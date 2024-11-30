##################
#  Daily Backup  #
##################

# Test environment configuration
BACKUP_DIR="/Users/davidroberts/projects/backup/test_env/test_env_setup"
TEMP_DIR="$HOME/temp"

# Files to backup
FILES=(
    "$HOME/.bashrc"
    "$HOME/.gitconfig"
    "$HOME/.bash_scripts/" 
)
# Convert array to comma-separated string
FILES_STRING=$(IFS=,; echo "${FILES[*]}")

check_daily_backup() {
    local last_run_file="$HOME/.backup_last_run"
    local current_time=$(date +%s)  # Current time in seconds
    local one_day_seconds=$((24 * 60 * 60))  # One day in seconds

    # Check if the last run file exists
    if [[ -f "$last_run_file" ]]; then
        local last_run_time=$(cat "$last_run_file")
        # Calculate the time difference
        local time_diff=$((current_time - last_run_time))
        # If less than a day has passed, exit the function
        if [[ $time_diff -lt $one_day_seconds ]]; then
            return
        fi
    fi

    # Run the backup script (without verbose mode)
    $HOME/.bash_scripts/bash_backup.sh -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING"

    # Update the last run file with the current time
    echo "$current_time" > "$last_run_file"
}

# Run the daily backup check
check_daily_backup
