# ~/.bash_profile — login shell bootstrap
# Sources .bashrc so env vars and interactive config are available in login shells.

if [[ -f ~/.bashrc ]]; then
  source ~/.bashrc
fi
