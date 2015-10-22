# Get the aliases, PATH and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# load custom prompt
if [ -f $(readlink -f ~/.bash_profile | xargs dirname)/bash_prompt.sh ]; then
  . $(readlink -f ~/.bash_profile | xargs dirname)/bash_prompt.sh
fi

# load bash_completions from various sources
# the standard ones
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi
# from brew-installed sources if they exist
if [[ $(command -v brew) && -f $(brew --prefix)/etc/bash_completion ]]; then
  . $(brew --prefix)/etc/bash_completion
fi
# any custom ones
if [ -d $(readlink -f ~/.bash_profile | xargs dirname)/bash_completion ]; then
  for b in $(readlink -f ~/.bash_profile | xargs dirname)/bash_completion/*; do
    . $b
  done
fi

# this is a safe and sensible umask
umask 027

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
