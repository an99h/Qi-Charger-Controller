#!/usr/local/bin/python
#coding=utf-8
from sys import argv

def be_pack(f, nargs):
    r = bytearray()
    if not f or nargs == 0:
        return r
    while nargs:
        shift = (nargs - 1)*8
        value = (f >> shift) & 0xff
        r.append(value)
        nargs -= 1
    return r

def getCmdPackage(register, nargs,f):
    msg = bytearray([0xfa, register, nargs])
    if f:
        msg = msg + be_pack(int(f), nargs)
    crc = reduce(lambda x, y: x ^ y, msg)
    msg.append(crc)
    cmd = ""
    for m in msg:
        cmd = cmd + "%02x" %m
    print(cmd)

if __name__ == '__main__':

    if len(argv) == 4:
        getCmdPackage(int(argv[1],16),int(argv[2]),int(argv[3]))
    
    if len(argv) == 3:
        getCmdPackage(int(argv[1],16),int(argv[2]),"")
    if len(argv) == 1:
        print "hello world"
    

