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

# Run setup and show outputs for all versions
echo "=== Testing verbose dryrun ==="
setup
./test_paste/paste_bashrc_dryrun.sh

echo -e "\n=== Testing verbose live ==="
setup
./test_paste/paste_bashrc_live.sh

echo -e "\n=== Testing non-verbose dryrun ==="
setup
./test_paste/paste_bashrc_dryrun_nv.sh

echo -e "\n=== Testing non-verbose live ==="
setup
./test_paste/paste_bashrc_live_nv.sh
