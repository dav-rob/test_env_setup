#!/bin/bash

# Debug setting
DEBUG=false

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
    git commit -m "Cleanup test files"
    git push -u origin main
    cd ~/.bash_scripts/tests
    rm -f ~/.backup_last_run
}

# Run setup and show outputs for all versions
echo "=== Testing verbose dryrun ==="
setup
verify_changes "$(./paste_bashrc_dryrun.sh)" "9:0" "Verbose dry-run"

echo -e "\n=== Testing verbose live ==="
setup
verify_changes "$(./paste_bashrc_live.sh)" "9:0" "Verbose live"

echo -e "\n=== Testing non-verbose dryrun ==="
setup
verify_changes "$(./paste_bashrc_dryrun_nv.sh)" "9:0" "Non-verbose dry-run"

echo -e "\n=== Testing non-verbose live ==="
setup
verify_changes "$(./paste_bashrc_live_nv.sh)" "9:0" "Non-verbose live"
