# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

pulldir () {
	(cd $1 && git pull)
}

rgrepi () {
	grep -r -i "$1" $2
}

# avoid duplicates..
export HISTCONTROL=ignoredups:erasedups

# append history entries..
shopt -s histappend

# After each command, save and reload history
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

export PATH="$PATH:/home/tgamblin/go/bin"

# From https://thucnc.medium.com/how-to-show-current-git-branch-with-colors-in-bash-prompt-380d05a24745
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Find files with name that contain string
findwithstr() {
    result=$(find "$1" -name "$2" -exec grep -l "$3" {} \; | awk -F/ '{print $NF}')
    for entry in $result; do echo $entry; done
}

# Find files with name that don't contain string
findwithoutstr() {
    result=$(find "$1" -name "$2" -exec grep -l -v "$3" {} \; | awk -F/ '{print $NF}')
    for entry in $result; do echo $entry; done
}

# show git branch on the terminal prompt
export PS1="\u@\h \[\e[32m\]\w \[\e[91m\]\$(parse_git_branch)\[\e[00m\]$ "

# Avoid duplicates
HISTCONTROL=ignoredups:erasedups # Ubuntu default is ignoreboth
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend  # In Ubuntu this is already set by default
HISTSIZE=-1
HISTFILESIZE=-1

# After each command, append to the history file and reread it
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
. "$HOME/.cargo/env"

nomachine() {
    /usr/NX/bin/nxplayer --config /usr/NX/scripts/etc/localhost/player.cfg
}

ptest-testall() {
    for package in $(find ../meta/recipes-devtools/python/* -name *.bb -exec \
    grep -l "ptest" {} \; | awk -F'_' '{print $1}' | sed 's/.*\///' | sort -u); \
    do bitbake core-image-ptest-$package:do_testimage 2>&1 | tee \
    testimage_logs/$package-testimage.log; done
}

fix_host_for_ghostty() {
    infocmp -x xterm-ghostty | ssh tgamblin@$1 -- tic -x -
}
. "$HOME/.cargo/env"

export GRIM_DEFAULT_DIR=$HOME/grim
export XDG_SCREENSHOTS_DIR=$GRIM_DEFAULT_DIR
