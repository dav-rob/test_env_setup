#!/bin/bash

# Default values
BACKUP_DIR=""
FILES_TO_BACKUP=()
VERBOSE=0
DRY_RUN=0

# Parse all arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v) VERBOSE=1 ;;
        -d) DRY_RUN=1 ;;
        --backup-dir) 
            BACKUP_DIR="$2"
            shift ;;
        --files) 
            IFS=',' read -r -a FILES_TO_BACKUP <<< "$2"
            shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate required parameters
if [ -z "$BACKUP_DIR" ]; then
    echo "Error: --backup-dir is required"
    exit 1
fi

if [ ${#FILES_TO_BACKUP[@]} -eq 0 ]; then
    echo "Error: --files is required"
    exit 1
fi

# Flag to track if any changes were made
CHANGES_MADE=0
# Counter for number of file updates
FILE_UPDATES=0
# Counter for number of file deletions
FILE_DELETIONS=0
# Counter for number of directory changes
DIR_CHANGES=0

# Function to log messages with timestamps
log_message() {
    local msg="$1"
    if [[ "$msg" == dry-run:* || "$msg" == backup:* || "$msg" == summary:* ]]; then
        echo "$msg"
    elif [ $VERBOSE -eq 1 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg"
    fi
}

# Function to normalize path separators and remove ./ prefix
normalize_path() {
    local path="$1"
    # First normalize slashes and handle . and ..
    path=$(echo "$path" | sed -e 's#/\+#/#g' -e 's#/\./\?#/#g' -e 's#\(/[^/]\+\)/\.\./\?#\1#g')
    # Then remove leading ./
    path=${path#./}
    # Remove trailing / if present
    path=${path%/}
    echo "$path"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to get relative path for backup
get_backup_path() {
    local source="$1"
    
    # If it's a directory, preserve the structure
    if [ -d "$source" ]; then
        local relative_path="${source#$HOME/}"
        relative_path=$(normalize_path "$relative_path")
        echo "$BACKUP_DIR/$relative_path"
    else
        # For files, strip all directory prefixes
        local filename=$(basename "$source")
        echo "$BACKUP_DIR/$filename"
    fi
}

files_differ() {
    local file1="$1"
    local file2="$2"
    
    # Check if source file exists
    if [ ! -f "$file1" ]; then
        [ $VERBOSE -eq 1 ] && log_message "Source file does not exist: $file1"
        return 1
    fi
    
    # If destination doesn't exist, files differ
    if [ ! -f "$file2" ]; then
        [ $VERBOSE -eq 1 ] && log_message "Destination file does not exist: $file2"
        return 0
    fi
    
    # Compare files with cmp (returns 0 if files are identical)
    if ! cmp -s "$file1" "$file2"; then
        [ $VERBOSE -eq 1 ] && log_message "Files differ: $file1 and $file2"
        if [ $VERBOSE -eq 1 ]; then
            echo "Diff output:"
            diff "$file1" "$file2" || true
        fi
        return 0
    fi
    
    [ $VERBOSE -eq 1 ] && log_message "Files are identical"
    return 1
}

# Function to process files in a directory
process_directory() {
    local source="$1"
    local dest="$2"
    local in_dry_run="$3"
    local changes_detected=0
    
    # Use find to get all regular files in the directory
    while IFS= read -r -d '' file; do
        # Get clean paths
        local relative_path=$(normalize_path "${file#$source/}")
        local source_file="$source/$relative_path"
        local dest_file="$dest/$relative_path"
        
        if files_differ "$source_file" "$dest_file"; then
            if [ $in_dry_run -eq 1 ]; then
                [ $VERBOSE -eq 1 ] && log_message "Would backup file: $source_file"
                ((FILE_UPDATES++))
            else
                [ $VERBOSE -eq 1 ] && log_message "Backing up file: $source_file"
                mkdir -p "$(dirname "$dest_file")"
                cp -f "$source_file" "$dest_file"
                ((FILE_UPDATES++))
            fi
            changes_detected=1
        fi
    done < <(find "$source" -type f -print0)
    
    if [ $changes_detected -eq 1 ]; then
        ((DIR_CHANGES++))
    fi
}

# Function to check for files to be deleted
check_deletions() {
    local in_dry_run="$1"
    local current_files=()
    local current_paths=()
    
    # Build array of current file paths and their full paths
    for item in "${FILES_TO_BACKUP[@]}"; do
        if [ -d "$item" ]; then
            # Get the directory name relative to HOME
            local dir_name=$(normalize_path "${item#$HOME/}")
            while IFS= read -r -d '' file; do
                # Get clean paths relative to the directory
                local relative_path=$(normalize_path "${file#$item/}")
                # Add the directory prefix to match backup structure
                local backup_path="$dir_name/$relative_path"
                current_paths+=("$backup_path")
                [ $VERBOSE -eq 1 ] && log_message "Adding to current paths: $backup_path"
            done < <(find "$item" -type f -print0)
        else
            current_files+=("$(basename "$item")")
        fi
    done

    # Check backup directory recursively for files that should be deleted
    while IFS= read -r -d '' file; do
        # Skip .git files
        if [[ "$file" == *"/.git/"* ]]; then
            continue
        fi

        # Get clean paths relative to backup directory
        local relative_path=$(normalize_path "${file#$BACKUP_DIR/}")
        local basename=$(basename "$file")
        local found=0

        # Check both full paths and basenames
        for path in "${current_paths[@]}"; do
            path=$(normalize_path "$path")
            if [ "$relative_path" == "$path" ]; then
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            for name in "${current_files[@]}"; do
                if [ "$basename" == "$name" ]; then
                    found=1
                    break
                fi
            done
        fi

        if [ $found -eq 0 ]; then
            if [ $in_dry_run -eq 1 ]; then
                [ $VERBOSE -eq 1 ] && log_message "Would delete file: $relative_path"
                ((FILE_DELETIONS++))
            else
                [ $VERBOSE -eq 1 ] && log_message "Deleting file: $relative_path"
                rm -f "$file"
                ((FILE_DELETIONS++))
            fi
            CHANGES_MADE=1
        fi
    done < <(find "$BACKUP_DIR" -type f -print0)
}

# Function to backup a file or directory
backup_item() {
    local source="$1"
    local dest=$(get_backup_path "$source")
    local dest_dir=$(dirname "$dest")

    # Check if source exists
    if [ ! -e "$source" ]; then
        [ $VERBOSE -eq 1 ] && log_message "Warning: $source does not exist"
        return
    fi

    [ $VERBOSE -eq 1 ] && log_message "Checking: $source"

    # Create destination directory if it doesn't exist
    [ $DRY_RUN -eq 0 ] && mkdir -p "$dest_dir"

    # For directories, process all files within
    if [ -d "$source" ]; then
        process_directory "$source" "$dest" "$DRY_RUN"
    # For files, use direct content comparison
    else
        if files_differ "$source" "$dest"; then
            if [ $DRY_RUN -eq 1 ]; then
                [ $VERBOSE -eq 1 ] && log_message "Would backup file: $source"
                [ $VERBOSE -eq 1 ] && log_message "Updates in $source:"
            else
                [ $VERBOSE -eq 1 ] && log_message "Updates detected in file: $source"
                cp -f "$source" "$dest"
            fi
            CHANGES_MADE=1
            ((FILE_UPDATES++))
        else
            [ $VERBOSE -eq 1 ] && log_message "No updates detected in: $source"
        fi
    fi
}

# Function to check required commands
check_requirements() {
    local required_commands=("git" "rsync" "diff" "cmp")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -ne 0 ]; then
        log_message "Error: Required commands not found: ${missing_commands[*]}"
        exit 1
    fi
}

# Function to handle git operations
handle_git_operations() {
    local in_dry_run=$1
    local total_changes=$((FILE_UPDATES + FILE_DELETIONS))
    
    # First output the changes summary
    if [ $total_changes -gt 0 ]; then
        if [ $in_dry_run -eq 1 ]; then
            local msg="dry-run: "
            if [ $FILE_DELETIONS -gt 0 ]; then
                msg+="$FILE_UPDATES updates and $FILE_DELETIONS deletions would be made"
            else
                msg+="$FILE_UPDATES file(s) would be updated"
            fi
            log_message "$msg"
        else
            local msg="backup: "
            if [ $FILE_DELETIONS -gt 0 ]; then
                msg+="$FILE_UPDATES updates and $FILE_DELETIONS deletions made"
            else
                msg+="$FILE_UPDATES file(s) updated"
            fi
            log_message "$msg"
        fi
    else
        if [ $in_dry_run -eq 1 ]; then
            log_message "dry-run: no updates would be made"
        else
            log_message "backup: no updates"
        fi
        return
    fi
    
    # Navigate to backup directory
    cd "$BACKUP_DIR" || exit 1

    # Check if this is a git repository
    if [ ! -d .git ]; then
        if [ $in_dry_run -eq 1 ]; then
            [ $VERBOSE -eq 1 ] && log_message "Would initialize git repository"
        else
            git init
            git config --local user.email "test@example.com"
            git config --local user.name "Test User"
        fi
    fi

    # Get git status
    local git_status=$(git status --porcelain)
    
    if [ ! -z "$git_status" ]; then
        if [ $in_dry_run -eq 1 ]; then
            [ $VERBOSE -eq 1 ] && log_message "Would commit the following updates:"
            [ $VERBOSE -eq 1 ] && echo "$git_status"
        else
            [ $VERBOSE -eq 1 ] && log_message "Committing updates:"
            [ $VERBOSE -eq 1 ] && echo "$git_status"
            
            # Add all changes
            git add .

            # Commit with timestamp
            if [ $VERBOSE -eq 1 ]; then
                git commit -m "Auto backup: $(date '+%Y-%m-%d %H:%M:%S')"
                git push -u origin main
            else
                git commit -m "Auto backup: $(date '+%Y-%m-%d')" > /dev/null 2>&1
                git push -u origin main > /dev/null 2>&1
            fi

            if [ $? -eq 0 ]; then
                [ $VERBOSE -eq 1 ] && log_message "Backup completed"
                local msg="summary: "
                if [ $FILE_DELETIONS -gt 0 ]; then
                    msg+="$FILE_UPDATES updates and $FILE_DELETIONS deletions made"
                else
                    msg+="$FILE_UPDATES file(s) updated"
                fi
                log_message "$msg"
            else
                log_message "Error: Failed to push to GitHub"
                exit 1
            fi
        fi
    fi
}

# Main backup function
main() {
    # Check requirements first
    check_requirements

    if [ $DRY_RUN -eq 1 ]; then
        [ $VERBOSE -eq 1 ] && log_message "Starting dry run backup process..."
    else
        [ $VERBOSE -eq 1 ] && log_message "Starting backup process..."
    fi


    # Process each file/directory
    for item in "${FILES_TO_BACKUP[@]}"; do
        backup_item "$item"
    done

    # Check for files that need to be deleted
    check_deletions $DRY_RUN

    # Handle git operations
    handle_git_operations $DRY_RUN
}

# Execute main function
main "$@"
