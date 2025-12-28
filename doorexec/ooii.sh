#!/bin/bash
DOORBAT="ooii.bat"
export HOME="/opt/photonbbs"
export TERM="ansi"

# DOSEMU CPU optimization - be nice to other processes
export DOSEMU_HOGTHRESHOLD=1

dosemu -t -quiet -I "serial { com 1 virtual }" "c:\\doors\\$DOORBAT $2" 2>/dev/null
rm -f $HOME/doors/ooii/oonode.dat
reset
