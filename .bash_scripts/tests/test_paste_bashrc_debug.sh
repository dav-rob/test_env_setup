#!/bin/bash

# Debug setting
DEBUG=true

# Function to verify number of changes
verify_changes() {
    local output="$1"
    local expected_changes="$2"  # Format: "updates:deletions"
    local test_name="$3"
    
    # Parse expected updates and deletions
    local expected_updates=$(echo "$expected_changes" | cut -d: -f1)
    local expected_deletions=$(echo "$expected_changes" | cut -d: -f2)
    
    # Print the full output for debugging
    if [ "$DEBUG" = true ]; then
        echo "Full output for $test_name:"
        echo "$output"
        echo "------------------------"
    fi
    
    # Extract the number of updates and deletions from the output
    local updates="0"
    local deletions="0"
    
    if [[ "$output" =~ ([0-9]+)[[:space:]]+"file".*"would be updated" ]]; then
        updates="${BASH_REMATCH[1]}"
    elif [[ "$output" =~ ([0-9]+)[[:space:]]+"file".*"updated" ]]; then
        updates="${BASH_REMATCH[1]}"
    elif [[ "$output" =~ ([0-9]+)[[:space:]]+"updates".*"would be made" ]]; then
        updates="${BASH_REMATCH[1]}"
    elif [[ "$output" =~ ([0-9]+)[[:space:]]+"updates".*"made" ]]; then
        updates="${BASH_REMATCH[1]}"
    fi
    
    if [[ "$output" =~ ([0-9]+)[[:space:]]+"file".*"would be deleted" ]]; then
        deletions="${BASH_REMATCH[1]}"
    elif [[ "$output" =~ ([0-9]+)[[:space:]]+"file".*"deleted" ]]; then
        deletions="${BASH_REMATCH[1]}"
    elif [[ "$output" =~ ([0-9]+)[[:space:]]+"deletions".*"would be made" ]]; then
        deletions="${BASH_REMATCH[1]}"
    elif [[ "$output" =~ ([0-9]+)[[:space:]]+"deletions".*"made" ]]; then
        deletions="${BASH_REMATCH[1]}"
    fi
    
    if [[ "$output" =~ "no updates" ]]; then
        updates="0"
        deletions="0"
    fi
    
    local test_passed=1
    if [ "$updates" != "$expected_updates" ]; then
        echo "✗ $test_name failed: Expected $expected_updates updates, got $updates"
        test_passed=0
    fi
    
    if [ "$deletions" != "$expected_deletions" ]; then
        echo "✗ $test_name failed: Expected $expected_deletions deletions, got $deletions"
        test_passed=0
    fi
    
    if [ $test_passed -eq 1 ]; then
        echo "✓ $test_name passed: Expected $expected_updates updates and $expected_deletions deletions, got $updates updates and $deletions deletions"
        return 0
    fi
    return 1
}

# Test environment setup
setup() {
    cd /Users/davidroberts/projects/backup/test_env/test_env_setup
    rm -rf .bash_scripts/ .bashrc .gitconfig 
    if [ "$DEBUG" = true ]; then
        git commit -m "Cleanup test files"
        git push -u origin main
    else
        git commit -m "Cleanup test files" &>/dev/null
        git push -u origin main &>/dev/null
    fi
    cd ~/.bash_scripts/tests
    rm -f ~/.backup_last_run
}

# Lightweight setup that only resets the last run counter
setup_lite() {
    rm -f ~/.backup_last_run
}

# Add test files for backup testing
add_test_files() {
    mkdir -p "$HOME/temp/test_dir"
    touch "$HOME/temp/file1.txt"
    touch "$HOME/temp/file2.txt"
    touch "$HOME/temp/test_dir/dir_file1.txt"
    touch "$HOME/temp/test_dir/dir_file2.txt"
}

clean_up_test_files() {
    rm -f "$HOME/temp/file1.txt" "$HOME/temp/file2.txt"
    rm -rf "$HOME/temp/test_dir"
}

# Function to run test with output control
run_test() {
    local script="$1"
    local test_name="$2"
    local expected_changes="$3"
    if [ "$DEBUG" = true ]; then
        verify_changes "$($script)" "$expected_changes" "$test_name"
    else
        verify_changes "$($script 2>/dev/null)" "$expected_changes" "$test_name"
    fi
    return $?  # Return verify_changes result (0 for pass, 1 for fail)
}

# Initialize failure counter
failures=0

# Run setup and show outputs for all versions
echo "=== Testing verbose dryrun ==="
setup
run_test "./paste_bashrc_dryrun.sh" "Verbose dry-run" "10:0"
failures=$((failures + $?))

echo -e "\n=== Testing verbose live ==="
setup
run_test "./paste_bashrc_live.sh" "Verbose live" "10:0"
failures=$((failures + $?))

echo -e "\n=== Testing non-verbose dryrun ==="
setup
run_test "./paste_bashrc_dryrun_nv.sh" "Non-verbose dry-run" "10:0"
failures=$((failures + $?))

echo -e "\n=== Testing non-verbose live ==="
setup
run_test "./paste_bashrc_live_nv.sh" "Non-verbose live" "10:0"
failures=$((failures + $?))

echo -e "\n=== Testing non-verbose live with custom files ==="
setup
run_test "./paste_bashrc_live_nv.sh" "Non-verbose live" "10:0"
failures=$((failures + $?))

setup_lite
export DR_BACKUP_FILES="$HOME/.gitconfig,$HOME/.bash_scripts/"
run_test "./paste_bashrc_live_nv.sh" "Non-verbose live with custom files" "0:1"
failures=$((failures + $?))
unset DR_BACKUP_FILES

setup_lite
add_test_files
export DR_BACKUP_FILES="$HOME/.gitconfig,$HOME/.bash_scripts/,$HOME/temp/file1.txt,$HOME/temp/file2.txt,$HOME/temp/test_dir/"
run_test "./paste_bashrc_live_nv.sh" "Non-verbose live with additional files" "4:0"
failures=$((failures + $?))
unset DR_BACKUP_FILES

setup_lite
add_test_files
# Append text to file2.txt and remove file1.txt and dir_file1.txt from backup
echo "Updated content" >> "$HOME/temp/file2.txt"
export DR_BACKUP_FILES="$HOME/.gitconfig,$HOME/.bash_scripts/,$HOME/temp/file2.txt,$HOME/temp/test_dir/dir_file2.txt"
run_test "./paste_bashrc_live_nv.sh" "Non-verbose live with updates and deletions" "2:2"
failures=$((failures + $?))
unset DR_BACKUP_FILES

# Clean up
setup
clean_up_test_files

# Report results
echo -e "\n"
if [ $failures -eq 0 ]; then
    echo "All tests passed"
else
    echo "$failures tests failed"
fi
exit $failures
