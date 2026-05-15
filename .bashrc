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

# general tooling exports and sourcing

export PATH="$PATH:/home/tgamblin/go/bin"
export PATH=~/.npm-global/bin:$PATH
. "$HOME/.cargo/env"

# tweaks for showing git branch info on the prompt

## From https://thucnc.medium.com/how-to-show-current-git-branch-with-colors-in-bash-prompt-380d05a24745
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

## show git branch on the terminal prompt
export PS1="\u@\h \[\e[32m\]\w \[\e[91m\]\$(parse_git_branch)\[\e[00m\]$ "

# bash history tweaks

## Avoid duplicates
HISTCONTROL=ignoredups:erasedups

## When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
HISTSIZE=-1
HISTFILESIZE=-1

## After each command, append to the history file and reread it
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# handy stuff for bitbake-setup

## export the repo path
export BBSPATH=~/workspace/yocto/bitbake

## short command for quickly updating the main bitbake checkout
bbsupdate() {
    echo "Updating bitbake checkout at ${BBSPATH}"
    (cd "${BBSPATH}" && git fetch origin && git reset --hard origin/master)
}

## shorten the bitbake-setup invocation from '$BBSPATH/bin/bitbake-setup' to 'bbs'
alias bbs='${BBSPATH}/bin/bitbake-setup'

# miscellaneous helper functions

## Find files with name that contain string
findwithstr() {
    result=$(find "$1" -name "$2" -exec grep -l "$3" {} \; | awk -F/ '{print $NF}')
    for entry in $result; do echo $entry; done
}

## Find files with name that don't contain string
findwithoutstr() {
    result=$(find "$1" -name "$2" -exec grep -l -v "$3" {} \; | awk -F/ '{print $NF}')
    for entry in $result; do echo $entry; done
}

## start nomachine from the terminal
nomachine() {
    /usr/NX/bin/nxplayer --config /usr/NX/scripts/etc/localhost/player.cfg
}

## run ptests with testimage
ptest-testall() {
    for package in $(find ../meta/recipes-devtools/python/* -name *.bb -exec \
    grep -l "ptest" {} \; | awk -F'_' '{print $1}' | sed 's/.*\///' | sort -u); \
    do bitbake core-image-ptest-$package:do_testimage 2>&1 | tee \
    testimage_logs/$package-testimage.log; done
}

## pull latest in repo directory passed as argument
pulldir () {
	(cd $1 && git pull)
}

## recursive search for a string '$1' (no case sensitivity) in path '$2'
rgrepi () {
	grep -r -i "$1" $2
}
