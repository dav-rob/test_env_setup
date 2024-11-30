#!/bin/bashexport TERM=xterm-color
export CLICOLOR=1
export GREP_OPTIONS='--color=auto'
# export LSCOLORS=Exfxcxdxbxegedabagacad
export LSCOLORS=gxfxcxdxbxegedabagacad # Dark lscolor scheme
# Don't put duplicate lines in your bash history
export HISTCONTROL=ignoredups
# increase history limit (100KB or 5K entries)
export HISTFILESIZE=100000
export HISTSIZE=5000

# Readline, the line editing library that bash uses, does not know
# that the terminal escape sequences do not take up space on the
# screen. The redisplay code assumes, unless told otherwise, that
# each character in the prompt is a `printable' character that
# takes up one character position on the screen. 

# You can use the bash prompt expansion facility (see the PROMPTING
# section in the manual page) to tell readline that sequences of
# characters in the prompt strings take up no screen space. 

# Use the \[ escape to begin a sequence of non-printing characters,
# and the \] escape to signal the end of such a sequence.
# Define some colors first:
RED='\[\e[1;31m\]'
BOLDYELLOW='\[\e[1;33m\]'
GREEN='\[\e[0;32m\]'
BLUE='\[\e[1;34m\]'
DARKBROWN='\[\e[1;33m\]'
DARKGRAY='\[\e[1;30m\]'
CUSTOMCOLORMIX='\[\e[1;30m\]'
DARKCUSTOMCOLORMIX='\[\e[1;32m\]'
LIGHTBLUE="\[\033[1;36m\]"
PURPLE='\[\e[1;35m\]' #git branch
# EG: GREEN="\[\e[0;32m\]" 
#PURPLE='\[\e[1;35m\]'
#BLUE='\[\e[1;34m\]'
NC='\[\e[0m\]' # No Color
PS1="${LIGHTBLUE}\\u ${BOLDYELLOW}[\\W] ${PURPLE}\$(parse_git_branch)${DARKCUSTOMCOLORMIX}$ ${NC}"
#PS1="${DARKCUSTOMCOLORMIX}\\u@\h:\\W]${PURPLE}\$(parse_git_branch)${DARKCUSTOMCOLORMIX}$ ${NC}"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # Load RVM function

touchall()
{
  tmp=`echo "$1" | sed 's/\"//'`
  find . -maxdepth 1 -name "$tmp" -print0 | xargs -0 touch -c
  find . -maxdepth 1 -name "$tmp" -print0 | xargs -0 ls -l
}

list_detailed_more()
{
	ls -lah $1 | more
}

#Used in the PS1 prompt variable to display the current Git branch name in the terminal prompt
function parse_git_branch() {
 git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
#export -f parse_git_branch - this line causes errors in VSCode

# show PATH variable entries on separate lines
path_parse() {
    echo "$PATH" | tr ':' '\n'
}

# Safe rm procedure
safe_rm()
{
    # Cycle through each argument for deletion
    for file in $*; do
        if [ -e $file ]; then

            # Target exists and can be moved to Trash safely
            if [ ! -e ~/.Trash/$file ]; then
                mv $file ~/.Trash

            # Target exists and conflicts with target in Trash
            elif [ -e ~/.Trash/$file ]; then

                # Increment target name until 
                # there is no longer a conflict
                i=1
                while [ -e ~/.Trash/$file.$i ];
                do
                    i=$(($i + 1))
                done

                # Move to the Trash with non-conflicting name
                mv $file ~/.Trash/$file.$i
            fi

        # Target doesn't exist, return error
        else
            echo "rm: $file: No such file or directory";
        fi
    done
}

function github() {
  #call from a local repo to open the repository on github in browser
  giturl=$(git config --get remote.origin.url)
  if [ "$giturl" == "" ]
    then
     echo "Not a git repository or no remote.origin.url set"
     exit 1;
  fi
  giturl=${giturl/git\@github\.com\:/https://github.com/}
  giturl=${giturl/\.git//}
  echo $giturl
  open $giturl
}

json() { echo $* | python -mjson.tool; }

##################
#  Daily Backup  #
##################
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
    $HOME/.bash_scripts/bash_backup.sh

    # Update the last run file with the current time
    echo "$current_time" > "$last_run_file"
}

# Function to check outdated brew packages and run once a week
check_brew_outdated() {
    local last_run_file="$HOME/.brew_last_run"
    local current_time=$(date +%s)  # Current time in seconds
    local one_week_seconds=$((7 * 24 * 60 * 60))  # One week in seconds

    # Check if the last run file exists
    if [[ -f "$last_run_file" ]]; then
        local last_run_time=$(cat "$last_run_file")
        # Calculate the time difference
        local time_diff=$((current_time - last_run_time))
        # If less than a week has passed, exit the function
        if [[ $time_diff -lt $one_week_seconds ]]; then
            return
        fi
    fi

    # Run the brew outdated command
    echo "outdated brew packages:"
    brew outdated

    # Update the last run file with the current time
    echo "$current_time" > "$last_run_file"
}

###########################
##   CLI Completions     ##
###########################


#bash git completion
if [ -f `brew --prefix`/etc/bash_completion ]; then
  . `brew --prefix`/etc/bash_completion
fi

# enable git completion through bash completion project installed using brew
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"


###############################
##         Aliases           ##
###############################

alias reload='source ~/.bashrc' # 'source ~/.bash_profile && source ~/.bashrc'
alias versions="python --version && ruby -v && rails -v && node --version && mongo --version && postgres --version"
alias ls='ls -hp'
alias ll='pwd && ls -l'
alias la='ls -la'
alias l='ls -CF'
alias cl='clear'
alias cll="clear; ls -lAh"
alias ..="cd .."
alias ..2="cd ../../"
alias ..3="cd ../../../"
alias back='cd -'
alias ~='cd ~'
alias o='open'
alias bp='mate ~/.bash_profile'
alias trash='safe_rm'
alias grep='grep -H -n'
alias rm='rm'
alias cp='cp -i'
alias mv='mv -i'
alias cwd='pwd | tr -d "\r\n" | pbcopy' #copy working directory
alias where="pwd"
alias h='history'
alias ppath="echo $PATH | tr ':' '\n'" #print path
alias untar="tar -xvf"
alias cputemp='sudo powermetrics --samplers smc |grep -i "CPU die temperature"'
# Extract tags from ruby files
# alias rtags="find . -name '*.rb' | xargs /usr/bin/ctags -R -a -f TAGS"

###################
## applications ##
###################
#alias idle27="python -m idlelib.idle"

alias tedit="open -a /Applications/TextEdit.app/Contents/MacOS/TextEdit"
alias chrome="open -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias mongod="mongod --dbpath ~/data/db"
#
#From man less , v Invokes an editor to edit the current file being viewed. 
#The editor is taken from the environment variable VISUAL if defined, 
#or EDITOR if VISUAL is not defined, 
#or defaults to "vi" if neither VISUAL nor EDITOR is defined.
#
# It is most reliable to create a link to sublime - do this once, not in .bashrc
# ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
alias edit=subl
export VISUAL=subl
export EDITOR=subl


###################
##    Node.js    ##
###################
alias nodels='npm ls'
alias nlink='npm link'
alias loco='lcm server'
alias nlist='npm list -g --depth=0'


#####################
##    Docker       ##
#####################
alias dk='docker'
alias dkps='docker ps'
alias dkpsa='docker ps -a'
alias dkim='docker images'
alias dkrma='docker rm $(docker ps -a -q -f status=exited)'

#####################
##     K8S         ##
#####################
alias kclusters='kubectl config get-clusters'
alias kcontexts='kubectl config get-contexts | less -S'
alias kcurrent='kubectl config current-context'
alias kuse='kubectl config use-context'


#####################
##     GIT         ##
#####################
#alias repos='ls -la ~/workspace/repository'
#repo() { cd ~/workspace/repository/$*; } #jump to repo
#alias workspace='cd ~/workspace/'

# add github repo location
#     git remote add origin https://github.com/dav-rob/dav-rob.github.io.git
# configure to use ssh key authentication
#     git remote set-url origin git@github.com:dav-rob/dav-rob.github.io.git
alias gitpull='git pull origin main'
alias gitpush='git push -u origin main'


#####################
##     GCP         ##
#####################
# GCP gcloud calls to put binaries on path, and include gcloud completion
source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc
source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc
alias gconf='gcloud config list'
alias gconfs='gcloud config configurations list'
alias gactive='gcloud config configurations activate'
alias gproj='gcloud set project'
alias gclname='gcloud container clusters list --format=json | jq ".[].name"'
alias gzones='gcloud compute zones list'
# launches a web site that shows the city names of regions
alias gcities='open https://cloud.google.com/about/locations'

gclresize()
{
    clustername=$1
    clustersize=$2
    
    gcloud container clusters resize --zone us-central1-a $clustername --num-nodes=$clustersize 
}


#####################
##  Proxy Server   ##
#####################


#export http_proxy="http://localhost:8866"
#export https_proxy="http://localhost:8866"
export NODE_TLS_REJECT_UNAUTHORIZED="0"

#  Set USE_PROXY=true to enable in Apollo server
#
# export GLOBAL_AGENT_HTTP_PROXY="http://127.0.0.1:8866/"
# export GLOBAL_AGENT_HTTPS_PROXY="http://127.0.0.1:8866/"
# export ROARR_LOG=true
# export DEPLOY_ENV=DEV
# export USE_PROXY=true
# export NODE_EXTRA_CA_CERTS=""
#"/Users/davidroberts/projects/GraphQL/ApolloTutorial/fullstack-tutorial/start/server/FiddlerRootCertificate.crt"
# Set to true to log all calls to console


#####################
##     Brew        ##
#####################
alias blist='brew list --versions && brew list --versions --cask'
check_brew_outdated
export HOMEBREW_NO_ENV_HINTS=true

#####################
##      AWS        ##
#####################
export AWS_DEFAULT_REGION=eu-west-2
alias awswho='aws iam get-user | jq ".User.UserName"'
alias awsregion='aws ec2 describe-availability-zones | jq ".AvailabilityZones[].RegionName"'
alias awseuw1='export AWS_DEFAULT_REGION=eu-west-1'
alias awseuw2='export AWS_DEFAULT_REGION=eu-west-2'
alias awsinstances=$'aws ec2 describe-instances | jq \'[.Reservations | .[] | .Instances | .[] | select(.State.Name!="terminated") | {Name: (.Tags[]|select(.Key=="Name")|.Value), InstanceId: .InstanceId, State: .State.Name}]\''
alias awsecstart='aws ec2 start-instances --instance-ids '
alias awsecstop='aws ec2 stop-instances --instance-ids '
alias cdaws='cd ~/projects/learning/aws/materials/keypairs/'

##################
#      JAVA      #
##################
export PATH=$PATH:/Users/davidroberts/projects/bin/maven-3.8.3/bin
# list java homes using: /usr/libexec/java_home -V
export JAVA_HOME=`/usr/libexec/java_home -v 11.0.17`

#################
#   Node / TS   #
#################
export PORT=8080

################
#    ReactN    #
################
alias runmetro="npx react-native start"
alias runandroid="npx react-native run-android"
alias runios="npx react-native run-ios"

#################
#    Android    #
#################
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/emulator
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools

alias emu4a="emulator -avd Pixel_4a_API_31"
alias emulist="emulator -list-avds"

################
#    XCode     #
################
alias simlist="xcrun simctl list devices"
alias sim14='xcrun simctl boot "iPhone 14"'

#################
#     Ruby      #
#################
#ruby-build installs a non-Homebrew OpenSSL for each Ruby version installed and these are never upgraded.
#    To link Rubies to Homebrew's OpenSSL 1.1 (which is upgraded) add the following
#    to your /Users/davidroberts/.bash_profile:
#    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

# add rbenv path vars and init script
eval "$(rbenv init -)"
# install cocoapods using homebrew not rbenv ruby because 
# react native init script can't find rbenv environments
# because it doesn't see the rbenv shims
# put this after all other ruby shim: eval "$(rbenv init -)"
alias pod="/usr/local/bin/pod"
# rbenv commands
# this lists all the ruby versions in rbenv repo 
alias rversions='rbenv versions'
# this installs a new ruby version in rbenv repo e.g. rbenv install 3.3.5
alias rinstall='rbenv install'
# this makes a ruby version in rbenv the global ruby version e.g. rbenv global 3.3.5
alias rglobal='rbenv global'
# this lauches your jekyll website locally
alias jekpreview='bundle exec jekyll serve'


#################
#    Python     #
#################
#
# https://www.perplexity.ai/search/which-is-the-best-python-versi-RzbgL6tnRZ2VR1ZfyQYynA#1
# python@3.11 is 3.11.10
alias pyvenv="python3.11 -m venv .venv"
alias pyactivate="source .venv/bin/activate"
alias pyrequirements="pip freeze > requirements.txt"
# put Anaconda python and conda on path
export PATH="$PATH:/usr/local/anaconda3/bin"
# instructions from "pipx completions"
# first run this "pipx install argcomplete" then this works
eval "$(register-python-argcomplete pipx)"

#################
#     LLM       #
#################
#
#
alias llmlist="llm models list"
alias llmoptions="llm models --options"

#################
#  Datasette    #
#################
#
#Password!
export PASSWORD_HASH_1='pbkdf2_sha256$480000$8bf011e482424acff4b8dd09057e992d$YHpUvH1xWM99kNOGF/oqNjrXFDyOr8jfrlOOq9GBSwU='

##################
#   PLAY GROUND  #
##################
testfn()
{
    echo name of script is $0
    echo first argument is $1
    echo second argument is $2
    echo number of arguments is $#
}

##################
#   UNKNOWN      #
##################
PATH=$PATH:~/bin

# Run the daily backup check
# check_daily_backup

##################
#     Info       #
##################
echo ".bashrc loaded." 


# Test comment for backup script
# Test comment for backup script
