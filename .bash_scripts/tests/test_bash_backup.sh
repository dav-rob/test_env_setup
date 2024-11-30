#!/bin/bash

# Test backup script for bash_backup.sh

# Define backup directory
BACKUP_DIR="/Users/davidroberts/projects/backup/test_env/test_env_setup"
TEMP_DIR="$HOME/temp"

# Function to set up test environment
setup() {
    echo "Setting up test environment..."
    
    # Create temp directory if it doesn't exist
    mkdir -p "$TEMP_DIR"
    
    # Create test files and directory
    echo "Test content 1" > "$TEMP_DIR/testbackupfile1.txt"
    echo "Test content 2" > "$TEMP_DIR/testbackupfile2.txt"
    mkdir -p "$TEMP_DIR/testbackupdir1"
    echo "Test content in dir" > "$TEMP_DIR/testbackupdir1/testbackupdir1_file1.txt"
    
    # Define files to backup
    FILES=(
        "$TEMP_DIR/testbackupfile1.txt"
        "$TEMP_DIR/testbackupfile2.txt"
        "$TEMP_DIR/testbackupdir1"
    )
    
    # Convert array to comma-separated string
    FILES_STRING=$(IFS=,; echo "${FILES[*]}")
}

# Function to verify number of changes
verify_changes() {
    local output="$1"
    local expected_updates="$2"
    local test_name="$3"
    local expected_deletions="$4"  # New parameter for expected deletions
    
    # Print the full output for debugging
    echo "Full output for $test_name:"
    echo "$output"
    echo "------------------------"
    
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
    
    if [ ! -z "$expected_deletions" ] && [ "$deletions" != "$expected_deletions" ]; then
        echo "✗ $test_name failed: Expected $expected_deletions deletions, got $deletions"
        test_passed=0
    fi
    
    if [ $test_passed -eq 1 ]; then
        if [ ! -z "$expected_deletions" ]; then
            echo "✓ $test_name passed: Expected $expected_updates updates and $expected_deletions deletions, got $updates updates and $deletions deletions"
        else
            echo "✓ $test_name passed: Expected $expected_updates updates, got $updates"
        fi
        return 0
    fi
    return 1
}

# Function to run tests
run_tests() {
    local test_failed=0
    
    # Test 1: Initial backup tests
    echo "Running Test 1: Initial backup tests..."
    
    # Test 1.1: Verbose dry-run push
    echo "Running Test 1.1: Verbose dry-run push..."
    output=$(../bash_backup.sh -d -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "3" "Verbose dry-run" || test_failed=1  # Expect 3 files (2 standalone + 1 in directory)
    
    # Test 1.2: Non-verbose dry-run push
    echo "Running Test 1.2: Non-verbose dry-run push..."
    output=$(../bash_backup.sh -d --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "3" "Non-verbose dry-run" || test_failed=1  # Expect 3 files
    
    # Test 1.3: Verbose live push
    echo "Running Test 1.3: Verbose live push..."
    output=$(../bash_backup.sh -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "3" "Verbose live push" || test_failed=1  # Expect 3 files
    
    # Test 1.4: Non-verbose live push (should show no changes as files are already backed up)
    echo "Running Test 1.4: Non-verbose live push..."
    output=$(../bash_backup.sh --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "0" "Non-verbose live push" || test_failed=1

    # Test 2: New file in root level
    echo "Running Test 2: New file in root level..."
    echo "New root content" > "$TEMP_DIR/testbackupfile3.txt"
    FILES+=("$TEMP_DIR/testbackupfile3.txt")
    FILES_STRING=$(IFS=,; echo "${FILES[*]}")

    # Test 2.1: Verbose dry-run
    output=$(../bash_backup.sh -d -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "New root file - Verbose dry-run" || test_failed=1

    # Test 2.2: Non-verbose dry-run
    output=$(../bash_backup.sh -d --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "New root file - Non-verbose dry-run" || test_failed=1

    # Test 2.3: Non-verbose live push
    output=$(../bash_backup.sh --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "New root file - Non-verbose live push" || test_failed=1

    # Test 2.4: Verbose live push (should show no changes)
    output=$(../bash_backup.sh -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "0" "New root file - Verbose live push" || test_failed=1

    # Test 3: New file in subdirectory
    echo "Running Test 3: New file in subdirectory..."
    echo "New subdir content" > "$TEMP_DIR/testbackupdir1/testbackupdir1_file2.txt"

    # Test 3.1: Verbose dry-run
    output=$(../bash_backup.sh -d -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "New subdir file - Verbose dry-run" || test_failed=1

    # Test 3.2: Non-verbose dry-run
    output=$(../bash_backup.sh -d --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "New subdir file - Non-verbose dry-run" || test_failed=1

    # Test 3.3: Verbose live push
    output=$(../bash_backup.sh -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "New subdir file - Verbose live push" || test_failed=1

    # Test 3.4: Non-verbose live push (should show no changes)
    output=$(../bash_backup.sh --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "0" "New subdir file - Non-verbose live push" || test_failed=1

    # Test 4: Modified file in root level
    echo "Running Test 4: Modified file in root level..."
    echo "Modified root content" > "$TEMP_DIR/testbackupfile1.txt"

    # Test 4.1: Verbose dry-run
    output=$(../bash_backup.sh -d -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Modified root file - Verbose dry-run" || test_failed=1

    # Test 4.2: Non-verbose dry-run
    output=$(../bash_backup.sh -d --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Modified root file - Non-verbose dry-run" || test_failed=1

    # Test 4.3: Non-verbose live push
    output=$(../bash_backup.sh --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Modified root file - Non-verbose live push" || test_failed=1

    # Test 4.4: Verbose live push (should show no changes)
    output=$(../bash_backup.sh -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "0" "Modified root file - Verbose live push" || test_failed=1

    # Test 5: Modified file in subdirectory
    echo "Running Test 5: Modified file in subdirectory..."
    echo "Modified subdir content" > "$TEMP_DIR/testbackupdir1/testbackupdir1_file1.txt"

    # Test 5.1: Verbose dry-run
    output=$(../bash_backup.sh -d -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Modified subdir file - Verbose dry-run" || test_failed=1

    # Test 5.2: Non-verbose dry-run
    output=$(../bash_backup.sh -d --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Modified subdir file - Non-verbose dry-run" || test_failed=1

    # Test 5.3: Verbose live push
    output=$(../bash_backup.sh -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Modified subdir file - Verbose live push" || test_failed=1

    # Test 5.4: Non-verbose live push (should show no changes)
    output=$(../bash_backup.sh --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "0" "Modified subdir file - Non-verbose live push" || test_failed=1

    # Test 6: New folder with two files
    echo "Running Test 6: New folder with two files..."
    mkdir -p "$TEMP_DIR/testbackupdir2"
    echo "New folder file 1" > "$TEMP_DIR/testbackupdir2/testbackupdir2_file1.txt"
    echo "New folder file 2" > "$TEMP_DIR/testbackupdir2/testbackupdir2_file2.txt"
    FILES+=("$TEMP_DIR/testbackupdir2")
    FILES_STRING=$(IFS=,; echo "${FILES[*]}")

    # Test 6.1: Verbose dry-run
    output=$(../bash_backup.sh -d -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "2" "New folder with files - Verbose dry-run" || test_failed=1

    # Test 6.2: Non-verbose dry-run
    output=$(../bash_backup.sh -d --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "2" "New folder with files - Non-verbose dry-run" || test_failed=1

    # Test 6.3: Verbose live push
    output=$(../bash_backup.sh -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "2" "New folder with files - Verbose live push" || test_failed=1

    # Test 6.4: Non-verbose live push (should show no changes)
    output=$(../bash_backup.sh --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "0" "New folder with files - Non-verbose live push" || test_failed=1

    # Test 7: Remove root level file
    echo "Running Test 7: Remove root level file..."
    # Remove testbackupfile3.txt from FILES array
    FILES=(${FILES[@]/$TEMP_DIR\/testbackupfile3.txt})
    FILES_STRING=$(IFS=,; echo "${FILES[*]}")

    # Test 7.1: Verbose dry-run
    output=$(../bash_backup.sh -d -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Remove root file - Verbose dry-run" "1" || test_failed=1

    # Test 7.2: Non-verbose dry-run
    output=$(../bash_backup.sh -d --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Remove root file - Non-verbose dry-run" "1" || test_failed=1

    # Test 7.3: Non-verbose live push
    output=$(../bash_backup.sh --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Remove root file - Non-verbose live push" "1" || test_failed=1

    # Test 7.4: Verbose live push (should show no changes)
    output=$(../bash_backup.sh -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "0" "Remove root file - Verbose live push" || test_failed=1

    # Test 8: Remove file from testbackupdir1
    echo "Running Test 8: Remove file from testbackupdir1..."
    rm "$TEMP_DIR/testbackupdir1/testbackupdir1_file2.txt"

    # Test 8.1: Verbose dry-run
    output=$(../bash_backup.sh -d -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Remove subdir file - Verbose dry-run" "1" || test_failed=1

    # Test 8.2: Non-verbose dry-run
    output=$(../bash_backup.sh -d --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Remove subdir file - Non-verbose dry-run" "1" || test_failed=1

    # Test 8.3: Verbose live push
    output=$(../bash_backup.sh -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "1" "Remove subdir file - Verbose live push" "1" || test_failed=1

    # Test 8.4: Non-verbose live push (should show no changes)
    output=$(../bash_backup.sh --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "0" "Remove subdir file - Non-verbose live push" || test_failed=1

    # Test 9: Remove folder with two files
    echo "Running Test 9: Remove folder with two files..."
    # Remove testbackupdir2 from FILES array
    FILES=(${FILES[@]/$TEMP_DIR\/testbackupdir2})
    FILES_STRING=$(IFS=,; echo "${FILES[*]}")

    # Test 9.1: Verbose dry-run
    output=$(../bash_backup.sh -d -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "2" "Remove folder - Verbose dry-run" "2" || test_failed=1

    # Test 9.2: Non-verbose dry-run
    output=$(../bash_backup.sh -d --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "2" "Remove folder - Non-verbose dry-run" "2" || test_failed=1

    # Test 9.3: Non-verbose live push
    output=$(../bash_backup.sh --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "2" "Remove folder - Non-verbose live push" "2" || test_failed=1

    # Test 9.4: Verbose live push (should show no changes)
    output=$(../bash_backup.sh -v --backup-dir "$BACKUP_DIR" --files "$FILES_STRING")
    verify_changes "$output" "0" "Remove folder - Verbose live push" || test_failed=1

    return $test_failed
}

# Function to clean up test environment
cleanup() {
    echo "Cleaning up test environment..."
    
    # Remove test files and directory
    rm -rf "$TEMP_DIR/testbackupfile1.txt"
    rm -rf "$TEMP_DIR/testbackupfile2.txt"
    rm -rf "$TEMP_DIR/testbackupfile3.txt"
    rm -rf "$TEMP_DIR/testbackupdir1"
    rm -rf "$TEMP_DIR/testbackupdir2"
    
    # Clean up backup directory
    cd "$BACKUP_DIR" || exit 1
    rm -rf ./*
    git add .
    git commit -m "Cleanup test files"
    git push -u origin main
}

# Main execution
echo "Starting backup tests..."
setup
run_tests
test_result=$?
cleanup

if [ $test_result -eq 0 ]; then
    echo "All tests passed successfully!"
    exit 0
else
    echo "Some tests failed!"
    exit 1
fi
