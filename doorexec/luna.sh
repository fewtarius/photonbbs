#!/bin/bash
DOORBAT="luna.bat"
export HOME="/opt/photonbbs"
export TERM="ansi"

# DOSEMU CPU optimization - be nice to other processes
export DOSEMU_HOGTHRESHOLD=1

cp ${HOME}/doors/tmplts/lunatix.tmplt ${HOME}/doors/luna/lunatix.$2
cp ${HOME}/doors/tmplts/linkto.tmplt ${HOME}/doors/luna/linkto.$2
sed -i "s/DORINFO1.DEF/$2\\\DORINFO1.DEF/" ${HOME}/doors/luna/linkto.$2

# Launch DOSEMU
#dosemu -t -quiet "c:\\doors\\$DOORBAT $2" 2>/dev/null
dosemu -t -quiet -I "serial { com 1 virtual }" "c:\\doors\\$DOORBAT $2" 2>/dev/null
reset
