#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi

alias ls='ls --color=auto'
#PS1='[\u@\h \W]\$ '
PS1='\e[1;35m\W \$ \e[0m'

pfetch
