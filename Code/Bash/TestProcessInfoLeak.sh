#!/bin/bash
echo $$
PW=$1
echo ${PW} | wc -m
cat /proc/$$/cmdline
cat /proc/$$/environ
ps -ww -fp $$
