#!/bin/bash

# Common test functions for paste_bashrc tests
setup() {
    cd /Users/davidroberts/projects/backup/test_env/test_env_setup
    rm -rf .bash_scripts/ .bashrc .gitconfig 
    rm -rf *
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

setup_lite() {
    cd /Users/davidroberts/projects/backup/test_env/test_env_setup
    if [ "$DEBUG" = true ]; then
        git commit -m "Cleanup test files"
        git push -u origin main
    else
        git commit -m "Cleanup test files" &>/dev/null
        git push -u origin main &>/dev/null
    fi
    cd ~/.bash_scripts/tests
}

add_test_files() {
    mkdir -p "$HOME/temp/test_dir"
    echo "test file 1" > "$HOME/temp/file1.txt"
    echo "test file 2" > "$HOME/temp/file2.txt"
    echo "test dir file 1" > "$HOME/temp/test_dir/dir_file1.txt"
    echo "test dir file 2" > "$HOME/temp/test_dir/dir_file2.txt"
}

clean_up_test_files() {
    rm -f "$HOME/temp/file1.txt" "$HOME/temp/file2.txt"
    rm -f "$HOME/temp/test_dir/dir_file1.txt" "$HOME/temp/test_dir/dir_file2.txt"
    rm -rf "$HOME/temp/test_dir"
}

# Test verbose dry-run
test_verbose_dryrun() {
    setup
    if [ "$DEBUG" = true ]; then
        echo "Full output for Verbose dry-run:"
    fi
    output=$(DR_BACKUP_FILES="$HOME/.bashrc $HOME/.gitconfig $HOME/.bash_scripts/" ./paste_bashrc_dryrun.sh)
    if [ "$DEBUG" = true ]; then
        echo "$output"
    fi
    echo "------------------------"
    updates=$(echo "$output" | grep -o '[0-9]* file(s) would be updated' | cut -d' ' -f1)
    deletions=$(echo "$output" | grep -o '[0-9]* deletions' | cut -d' ' -f1)
    if [ "$updates" = "11" ] && [ -z "$deletions" ]; then
        echo "✓ Verbose dry-run passed: Expected 11 updates and 0 deletions, got $updates updates and ${deletions:-0} deletions"
    else
        echo "✗ Verbose dry-run failed: Expected 11 updates and 0 deletions, got $updates updates and ${deletions:-0} deletions"
        exit 1
    fi
}

# Test verbose live
test_verbose_live() {
    setup
    if [ "$DEBUG" = true ]; then
        echo "Full output for Verbose live:"
    fi
    output=$(DR_BACKUP_FILES="$HOME/.bashrc $HOME/.gitconfig $HOME/.bash_scripts/" ./paste_bashrc_live.sh)
    if [ "$DEBUG" = true ]; then
        echo "$output"
    fi
    echo "------------------------"
    updates=$(echo "$output" | grep -o '[0-9]* file(s) updated' | cut -d' ' -f1)
    deletions=$(echo "$output" | grep -o '[0-9]* deletions' | cut -d' ' -f1)
    if [ "$updates" = "11" ] && [ -z "$deletions" ]; then
        echo "✓ Verbose live passed: Expected 11 updates and 0 deletions, got $updates updates and ${deletions:-0} deletions"
    else
        echo "✗ Verbose live failed: Expected 11 updates and 0 deletions, got $updates updates and ${deletions:-0} deletions"
        exit 1
    fi
}

# Test non-verbose dry-run
test_nonverbose_dryrun() {
    setup
    if [ "$DEBUG" = true ]; then
        echo "Full output for Non-verbose dry-run:"
    fi
    output=$(DR_BACKUP_FILES="$HOME/.bashrc $HOME/.gitconfig $HOME/.bash_scripts/" ./paste_bashrc_dryrun_nv.sh)
    if [ "$DEBUG" = true ]; then
        echo "$output"
    fi
    echo "------------------------"
    updates=$(echo "$output" | grep -o '[0-9]* file(s) would be updated' | cut -d' ' -f1)
    deletions=$(echo "$output" | grep -o '[0-9]* deletions' | cut -d' ' -f1)
    if [ "$updates" = "11" ] && [ -z "$deletions" ]; then
        echo "✓ Non-verbose dry-run passed: Expected 11 updates and 0 deletions, got $updates updates and ${deletions:-0} deletions"
    else
        echo "✗ Non-verbose dry-run failed: Expected 11 updates and 0 deletions, got $updates updates and ${deletions:-0} deletions"
        exit 1
    fi
}

# Test non-verbose live
test_nonverbose_live() {
    setup
    if [ "$DEBUG" = true ]; then
        echo "Full output for Non-verbose live:"
    fi
    output=$(DR_BACKUP_FILES="$HOME/.bashrc $HOME/.gitconfig $HOME/.bash_scripts/" ./paste_bashrc_live_nv.sh)
    if [ "$DEBUG" = true ]; then
        echo "$output"
    fi
    echo "------------------------"
    updates=$(echo "$output" | grep -o '[0-9]* file(s) updated' | cut -d' ' -f1)
    deletions=$(echo "$output" | grep -o '[0-9]* deletions' | cut -d' ' -f1)
    if [ "$updates" = "11" ] && [ -z "$deletions" ]; then
        echo "✓ Non-verbose live passed: Expected 11 updates and 0 deletions, got $updates updates and ${deletions:-0} deletions"
    else
        echo "✗ Non-verbose live failed: Expected 11 updates and 0 deletions, got $updates updates and ${deletions:-0} deletions"
        exit 1
    fi
}

# Test non-verbose live with custom files
test_nonverbose_live_custom() {
    setup
    if [ "$DEBUG" = true ]; then
        echo "Full output for Non-verbose live with custom files:"
    fi
    add_test_files
    output=$(DR_BACKUP_FILES="$HOME/temp/file2.txt" ./paste_bashrc_live_nv.sh)
    if [ "$DEBUG" = true ]; then
        echo "$output"
    fi
    echo "------------------------"
    updates=$(echo "$output" | grep -o '[0-9]* updates' | cut -d' ' -f1)
    deletions=$(echo "$output" | grep -o '[0-9]* deletions' | cut -d' ' -f1)
    if [ "$updates" = "0" ] && [ "$deletions" = "1" ]; then
        echo "✓ Non-verbose live with custom files passed: Expected 0 updates and 1 deletions, got $updates updates and $deletions deletions"
    else
        echo "✗ Non-verbose live with custom files failed: Expected 0 updates and 1 deletions, got $updates updates and $deletions deletions"
        exit 1
    fi
}

# Test non-verbose live with additional files
test_nonverbose_live_additional() {
    setup_lite
    if [ "$DEBUG" = true ]; then
        echo "Full output for Non-verbose live with additional files:"
    fi
    output=$(DR_BACKUP_FILES="$HOME/temp/file1.txt $HOME/temp/test_dir/" ./paste_bashrc_live_nv.sh)
    if [ "$DEBUG" = true ]; then
        echo "$output"
    fi
    echo "------------------------"
    updates=$(echo "$output" | grep -o '[0-9]* file(s) updated' | cut -d' ' -f1)
    deletions=$(echo "$output" | grep -o '[0-9]* deletions' | cut -d' ' -f1)
    if [ "$updates" = "4" ] && [ -z "$deletions" ]; then
        echo "✓ Non-verbose live with additional files passed: Expected 4 updates and 0 deletions, got $updates updates and ${deletions:-0} deletions"
    else
        echo "✗ Non-verbose live with additional files failed: Expected 4 updates and 0 deletions, got $updates updates and ${deletions:-0} deletions"
        exit 1
    fi
}

# Test non-verbose live with updates and deletions
test_nonverbose_live_updates_deletions() {
    setup_lite
    if [ "$DEBUG" = true ]; then
        echo "Full output for Non-verbose live with updates and deletions:"
    fi
    echo "updated content" >> "$HOME/temp/file1.txt"
    output=$(DR_BACKUP_FILES="$HOME/temp/file1.txt $HOME/temp/file2.txt $HOME/temp/test_dir/" ./paste_bashrc_live_nv.sh)
    if [ "$DEBUG" = true ]; then
        echo "$output"
    fi
    echo "------------------------"
    updates=$(echo "$output" | grep -o '[0-9]* updates' | cut -d' ' -f1)
    deletions=$(echo "$output" | grep -o '[0-9]* deletions' | cut -d' ' -f1)
    if [ "$updates" = "2" ] && [ "$deletions" = "2" ]; then
        echo "✓ Non-verbose live with updates and deletions passed: Expected 2 updates and 2 deletions, got $updates updates and $deletions deletions"
    else
        echo "✗ Non-verbose live with updates and deletions failed: Expected 2 updates and 2 deletions, got $updates updates and $deletions deletions"
        exit 1
    fi
    clean_up_test_files
}

# Run all tests if sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    test_verbose_dryrun
    echo
    test_verbose_live
    echo
    test_nonverbose_dryrun
    echo
    test_nonverbose_live
    echo
    echo "=== Testing non-verbose live with custom files ==="
    test_nonverbose_live_custom
    test_nonverbose_live_additional
    test_nonverbose_live_updates_deletions
    echo
    echo "All tests passed"
fi
