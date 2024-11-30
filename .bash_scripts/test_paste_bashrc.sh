#!/bin/bash

# Test environment setup
setup() {
    cd /Users/davidroberts/projects/backup/test_env/test_env_setup
    rm -rf .bash_scripts/ .bashrc .gitconfig 
    git commit -m "Cleanup test files"
    git push -u origin main
    cd ~/.bash_scripts
    rm -f ~/.backup_last_run
}

# Run setup and show outputs
setup
echo "=== Dryrun output ==="
./paste_bashrc_dryrun.sh

setup
echo -e "\n=== Live output ==="
./paste_bashrc_live.sh

# Test that backup runs when no last_run file exists
#test_initial_backup() {
#    echo "Testing initial backup..."
#    setup
#    
#    # Run paste_bashrc_dryrun.sh
#    output=$(./paste_bashrc_dryrun.sh)
#    
#    # Verify backup was created
#    if [[ ! -f ~/.backup_last_run ]]; then
#        echo "FAIL: .backup_last_run file was not created"
#        return 1
#    fi
#    
#    echo "PASS: Initial backup test"
#    return 0
#}

# Test that backup is skipped when run within 24 hours
#test_skip_recent_backup() {
#    echo "Testing backup skip when recent..."
#    setup
#    
#    # Create recent last_run file (current time)
#    date +%s > ~/.backup_last_run
#    initial_time=$(cat ~/.backup_last_run)
#    
#    # Run paste_bashrc_dryrun.sh
#    output=$(./paste_bashrc_dryrun.sh)
#    
#    # Verify last_run wasn't updated (backup was skipped)
#    current_time=$(cat ~/.backup_last_run)
#    if [[ "$initial_time" != "$current_time" ]]; then
#        echo "FAIL: Backup ran when it should have been skipped"
#        return 1
#    fi
#    
#    echo "PASS: Recent backup skip test"
#    return 0
#}

# Test that backup runs when last_run is older than 24 hours
#test_old_backup() {
#    echo "Testing backup with old last_run..."
#    setup
#    
#    # Create old last_run file (>24h ago)
#    old_time=$(($(date +%s) - 25 * 60 * 60))  # 25 hours ago
#    echo "$old_time" > ~/.backup_last_run
#    
#    # Run paste_bashrc_dryrun.sh
#    output=$(./paste_bashrc_dryrun.sh)
#    
#    # Verify last_run was updated
#    current_time=$(cat ~/.backup_last_run)
#    if [[ "$old_time" == "$current_time" ]]; then
#        echo "FAIL: Backup didn't run when it should have"
#        return 1
#    fi
#    
#    echo "PASS: Old backup test"
#    return 0
#}

# Test that dryrun and live versions report same number of changes
#test_matching_changes() {
#    echo "Testing matching changes between dryrun and live..."
#    setup
#    
#    # Run both versions
#    dryrun_output=$(./paste_bashrc_dryrun.sh)
#    live_output=$(./paste_bashrc_live.sh)
#    
#    # Extract file count from dryrun
#    if [[ $dryrun_output =~ dry-run:\ ([0-9]+)\ file ]]; then
#        dryrun_total="${BASH_REMATCH[1]}"
#    elif [[ $dryrun_output =~ dry-run:\ no\ updates ]]; then
#        dryrun_total=0
#    else
#        echo "FAIL: Unexpected dryrun output format"
#        echo "Dryrun output: $dryrun_output"
#        return 1
#    fi
#    
#    # Extract update and deletion counts from live
#    if [[ $live_output =~ summary:\ ([0-9]+)\ updates\ and\ ([0-9]+)\ deletions ]]; then
#        live_updates="${BASH_REMATCH[1]}"
#        live_deletions="${BASH_REMATCH[2]}"
#        live_total=$((live_updates + live_deletions))
#    elif [[ $live_output =~ summary:\ ([0-9]+)\ file ]]; then
#        live_total="${BASH_REMATCH[1]}"
#    elif [[ $live_output =~ summary:\ no\ updates ]]; then
#        live_total=0
#    else
#        echo "FAIL: Unexpected live output format"
#        echo "Live output: $live_output"
#        return 1
#    fi
#    
#    # Compare the total number of changes
#    if [[ "$dryrun_total" != "$live_total" ]]; then
#        echo "FAIL: Mismatch in total number of changes"
#        echo "Dryrun total: $dryrun_total changes"
#        echo "Live total: $live_total changes (${live_updates} updates + ${live_deletions} deletions)"
#        return 1
#    fi
#    
#    echo "PASS: Matching changes test"
#    return 0
#}

# Run all tests
#echo "Running paste_bashrc_dryrun.sh tests..."
#test_initial_backup
#test_skip_recent_backup
#test_old_backup
#test_matching_changes

# Final cleanup
#setup
