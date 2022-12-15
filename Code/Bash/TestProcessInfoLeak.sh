#!/bin/bash
echo $$
PW=$1
echo ${PW} | wc -m
cat /proc/$$/cmdline
cat /proc/$$/environ
ps -ww -fp $$
# If you have HISTCONTROL set to ignoreboth or ignorespace and start bash commands at prompt with a space they don’t go in bash history
# . /path/to/script.sh args1text = in bash history, but nothing in /proc/<pid>/cmdline or in ps output
# prefix with a space, not in bash history, still not in ps or cmdline
# bash -c "run stuff" = all bets are off
