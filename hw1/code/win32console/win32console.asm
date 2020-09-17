;===============================================================================
;Program        : win32console
;Version        : 0.0.2
;Author         : Yeoh HS
;Date           : Nov 2009, edited in December 2017, January 2018
;Purpose        : a basic Win32 console program template
;Flat Assembler : 1.73.02
;Resources      : win32console.res (created with Pelles C)
;===============================================================================
format PE CONSOLE 4.0
entry start

include 'win32ax.inc'
include 'macro\if.inc'

;-------------------------------------------------------------------------------
macro println arg*
{
   cinvoke printf, '%s', arg
   cinvoke printf, CRLF
}

;-------------------------------------------------------------------------------
section '.code' code readable executable
start:
    stdcall getcmdargs
    println arg1
    println arg2
    println arg3

.finished:
    invoke  ExitProcess,0

;-------------------------------------------------------------------------------
proc showhelp
     println progtitle
     println arghelptitle
     println arg1help
     println arg2help
     println arg3help
     ret
endp

;-------------------------------------------------------------------------------
proc getcmdargs
    invoke GetCommandLine
    cinvoke strcpy,cmdline,eax

    cinvoke strtok, cmdline,strsep
    mov dword[strtokretval], eax

    cinvoke strtok, NULL,strsep
    mov dword[strtokretval],eax
    .if dword[strtokretval] = NULL
        stdcall showhelp
        jmp .finished
    .else
        cinvoke strcpy, arg1, dword[strtokretval]
    .endif

    cinvoke strtok, NULL,strsep
    mov dword[strtokretval], eax
    .if dword[strtokretval] = NULL
        stdcall showhelp
        jmp .finished
    .else
        cinvoke strcpy, arg2, dword[strtokretval]
    .endif

    cinvoke strtok, NULL,strsep
    mov dword[strtokretval], eax
    .if dword[strtokretval] = NULL
        stdcall showhelp
        jmp .finished
    .else
        cinvoke strcpy, arg3, dword[strtokretval]
    .endif
     jmp .okay
.finished:
    invoke  ExitProcess,0
.okay:
     ret
endp

;-------------------------------------------------------------------------------
section '.data' data readable writeable
    progtitle    db 'Win32 Console Program version 0.0.1 Copyright (c) 2018 by Yeoh HS',0
    arghelptitle db 'Usage: win32console arg1 arg2 arg3',0
    arg1help     db 'arg1 - help for argument #1',0
    arg2help     db 'arg2 - help for argument #2',0
    arg3help     db 'arg3 - help for argument #3',0     
    CRLF         db '',13,10,0
    strfmt       db '%s',0
    cmdline      rb 260
    strsep       db " ",0
    strtokretval rb 1024
    arg1         rb 32
    arg2         rb 32
    arg3         rb 32

;-------------------------------------------------------------------------------
section '.idata' import data readable writeable

library kernel32,'kernel32.dll',\
        user32,  'user32.dll',\
        msvcrt,  'msvcrt.dll'

include 'api\kernel32.inc'
include 'api\user32.inc'

import msvcrt,\
       strcpy, 'strcpy',\
       strtok, 'strtok',\
       printf, 'printf'
;-------------------------------------------------------------------------------
section '.rsrc' data readable resource from 'win32console.res'

; end of file ==================================================================
