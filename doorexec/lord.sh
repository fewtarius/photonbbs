#!/bin/bash
DOORBAT="lord.bat"
export HOME="/opt/photonbbs"
export TERM="ansi"

# DOSEMU CPU optimization - be nice to other processes
export DOSEMU_HOGTHRESHOLD=1

echo -e "**Seth Able's Node Data System, for node $2\r" >${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e "BBSNAME PhotonBBS\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e "BBSTYPE QBBS\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e "COMPORT 1\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e ";FOSSIL\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e "LOCKBAUD 38400\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e "STATUS ON\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e "STATFORE 3\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e "STATBACK 7\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e ";COLOR1\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e "NODIRECT\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e ";UNUSED\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e 'BBSDROP c:\\nodeinfo\\'$2'\r' >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e ";UNUSED\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e ";UNUSED\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat
echo -e ";UNUSED\r" >>${HOME}/.dosemu/drive_c/doors/lord/node$2.dat

dosemu -t -quiet -I "serial { com 1 virtual }" "c:\\doors\\$DOORBAT $2" 2>/dev/null
reset
