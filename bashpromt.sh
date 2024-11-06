# Enhanced Sexy Bash Prompt inspired by bash-git-prompt
#by Tech Logicals
# Define the colors
RESET="\[\033[0m\]"
BOLD="\[\033[1m\]"
RED="\[\033[0;31m\]"
GREEN="\[\033[0;32m\]"
YELLOW="\[\033[0;33m\]"
BLUE="\[\033[0;34m\]"
MAGENTA="\[\033[0;35m\]"
CYAN="\[\033[0;36m\]"
WHITE="\[\033[0;37m\]"

# Function to get the current git branch
function parse_git_branch() {
  git branch 2>/dev/null | grep '*' | sed 's/* //'
}

# Function to get the current git status
function parse_git_dirty() {
  [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit, working tree clean" ]] && echo "*"
}

# Function to get the current time
function current_time() {
  date +"%H:%M:%S"
}

# Set the prompt
export PS1="${BOLD}${CYAN}\u@\h ${WHITE}at ${YELLOW}\$(current_time) ${BLUE}\w${YELLOW}\$([[ -n \$(git branch 2>/dev/null) ]] && echo \" on \")${MAGENTA}\$(parse_git_branch)${RED}\$(parse_git_dirty)${RESET}\n\$ "

# End Generation Here

