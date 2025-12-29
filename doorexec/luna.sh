#!/bin/bash
DOORBAT="luna.bat"
export HOME="/opt/photonbbs"
export TERM="ansi"

# DOSEMU CPU optimization - be nice to other processes
export DOSEMU_HOGTHRESHOLD=1

# Create Luna-specific config file dynamically for this node
# This replaces the template file lunatix.tmplt with complete content
echo -e "Imenz Aine\r" >${HOME}/.dosemu/drive_c/doors/luna/lunatix.$2
echo -e "c:\\luna\\todays.txt\r" >>${HOME}/.dosemu/drive_c/doors/luna/lunatix.$2
echo -e "c:\\luna\\yester.txt\r" >>${HOME}/.dosemu/drive_c/doors/luna/lunatix.$2
echo -e "20\r" >>${HOME}/.dosemu/drive_c/doors/luna/lunatix.$2
echo -e "3\r" >>${HOME}/.dosemu/drive_c/doors/luna/lunatix.$2
echo -e "c:\\luna\\\r" >>${HOME}/.dosemu/drive_c/doors/luna/lunatix.$2
echo -e "\r" >>${HOME}/.dosemu/drive_c/doors/luna/lunatix.$2

# Create linkto file pointing to drop file directory
# This replaces the template file linkto.tmplt with complete content
echo -e "c:\\nodeinfo\\$2\\DORINFO1.DEF\r" >${HOME}/.dosemu/drive_c/doors/luna/linkto.$2
echo -e "07 01 25\r" >>${HOME}/.dosemu/drive_c/doors/luna/linkto.$2
echo -e "04 04 02\r" >>${HOME}/.dosemu/drive_c/doors/luna/linkto.$2
echo -e "12 01 06\r" >>${HOME}/.dosemu/drive_c/doors/luna/linkto.$2
echo -e "10 01 01 1\r" >>${HOME}/.dosemu/drive_c/doors/luna/linkto.$2
echo -e "05 01 07\r" >>${HOME}/.dosemu/drive_c/doors/luna/linkto.$2
echo -e "N81\r" >>${HOME}/.dosemu/drive_c/doors/luna/linkto.$2
echo -e "0\r" >>${HOME}/.dosemu/drive_c/doors/luna/linkto.$2
echo -e "2\r" >>${HOME}/.dosemu/drive_c/doors/luna/linkto.$2
echo -e "1\r" >>${HOME}/.dosemu/drive_c/doors/luna/linkto.$2
echo -e "1\r" >>${HOME}/.dosemu/drive_c/doors/luna/linkto.$2

# Launch DOSEMU
dosemu -t -quiet -I "serial { com 1 virtual }" "c:\\doors\\$DOORBAT $2" 2>/dev/null
reset
