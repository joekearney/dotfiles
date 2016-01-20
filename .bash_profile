
function loadIfExists() {
  local f=$1
  if [ -f $f ]; then
    . $f
  fi
}

# Get the aliases, PATH, DOT_FILES_DIR and functions.
loadIfExists ~/.bashrc

# Source global definitions
loadIfExists /etc/bashrc

# Source machine-local environment
loadIfExists ~/.local_env.sh

# load colours
loadIfExists $DOT_FILES_DIR/colour/.bash_color_vars

# Load RVM into a shell session *as a function*
# if file exists and is non-empty
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# load functions
loadIfExists ${DOT_FILES_DIR}/functions.sh
for thing in git sbt tunnelblick; do
  loadIfExists ${DOT_FILES_DIR}/$thing/$thing-functions.sh
done

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

# load custom prompt
if [ -f ${DOT_FILES_DIR}/bash_prompt.sh ]; then
  . ${DOT_FILES_DIR}/bash_prompt.sh
fi

# this is a safe and sensible umask
umask 027
