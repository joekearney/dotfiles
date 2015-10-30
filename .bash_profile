# Get the aliases, PATH and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

export DOT_FILES_DIR=$(readlink -f ~/.bash_profile | xargs dirname)

# load functions
if [ -f ${DOT_FILES_DIR}/functions.sh ]; then
  . ${DOT_FILES_DIR}/functions.sh
fi

# load custom prompt
if [ -f ${DOT_FILES_DIR}/bash_prompt.sh ]; then
  . ${DOT_FILES_DIR}/bash_prompt.sh
fi

# load bash_completions from various sources
# the standard ones -- this seems to break prompt on some hosts
#if [ -f /etc/bash_completion ]; then
#  . /etc/bash_completion
#fi
# from brew-installed sources if they exist
if [[ $(command -v brew) && -f $(brew --prefix)/etc/bash_completion ]]; then
  . $(brew --prefix)/etc/bash_completion
fi
# any custom ones
if [ -d ${DOT_FILES_DIR}/bash_completion ]; then
  for b in ${DOT_FILES_DIR}/bash_completion/*; do
    . $b
  done
fi

# this is a safe and sensible umask
umask 027

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
