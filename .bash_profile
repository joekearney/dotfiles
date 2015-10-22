# Get the aliases and functions
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

if [[ $(command -v brew) && -f $(brew --prefix)/etc/bash_completion ]]; then
  . $(brew --prefix)/etc/bash_completion
fi
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

umask 027

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
