;===============================================================================
;Program        : Win32SQLite
;Version        : 0.0.1
;Author         : Yeoh HS
;Date           : Nov 2009, edited in December 2017
;Purpose        : A way to use the SQLite3 DLL
;Flat Assembler : 1.73.01
;Resources      : Win32SQLite.res (created with Pelles C)
;===============================================================================

format PE CONSOLE 4.0
entry start

include 'win32axp.inc'
include 'macro\if.inc'

section '.data' data readable writeable
  CRLF        db '',13,10,0
  strfmt      db '%s',0

  errmsg      dd 0
  h3db        dd 0
  dbname      db 'win32sqlite.3db',0
  createsql   db 'CREATE TABLE mytable (a integer primary key, topic text, keywords text, notes text)',0
  sql         rb 1024
  addnew      db "INSERT INTO mytable (a, topic, keywords, notes) VALUES(NULL,'%s','%s','%s');",0
  ifield1     db "One's",0    ;input field, test apostrophe handling
  efield1     rb 80           ;encoded field
  dropsql     db 'DROP TABLE mytable',0
  sqlite_ver  dd ?
  delete      db "DELETE FROM mytable WHERE a = %d ;",0
  lpout       rb    1024
  lpfmt       db 'Number of records = %lu',0

  getrecord   db "SELECT * FROM mytable WHERE a = %d ;",0
  resultp     rb 2048
  nrow        dd 0
  ncol        dd 0
  field0      dd 0
  field1      dd 0
  field2      dd 0
  field3      dd 0

  update      db "UPDATE mytable SET topic='%s', keywords='%s', notes='%s' WHERE a=%d ;",0
  findrecord  db "SELECT * FROM mytable WHERE keywords LIKE '%s' ;",0
  listrecords db "SELECT * FROM mytable ;",0
  findtopic   db "SELECT * FROM mytable WHERE topic='%s' ;",0

;-------------------------------------------------------------------------------
section '.code' code readable executable
start:
     stdcall getsqlitever
     cinvoke printf, strfmt, 'SQLite version: '
     cinvoke printf, strfmt, [sqlite_ver] ;show SQLite version
     cinvoke printf, strfmt, CRLF

     stdcall createdb
     stdcall addnewrec,'topic 1','keywords 1','notes 1'
     stdcall encodeapostrophe,ifield1,efield1
     stdcall addnewrec,efield1,'keywords 2','notes 2'   ; test one field with apostrophe
     stdcall addnewrec,'topic 3','keywords 3','notes 3'
     stdcall addnewrec,'topic 1','keywords 1','notes 1'

     cinvoke printf, strfmt, 'Check for duplicate record, same topic'
     cinvoke printf, strfmt, CRLF
     stdcall checkduptopic,'topic 1'
     cinvoke printf, strfmt, CRLF

     cinvoke printf, strfmt, 'List all records:'
     cinvoke printf, strfmt, CRLF
     stdcall findrecords
     cinvoke printf, strfmt, CRLF

     cinvoke printf, strfmt, 'Get each record and show it.'
     cinvoke printf, strfmt, CRLF
     cinvoke printf, strfmt, 'Record #:'
     stdcall getarecord,1
     cinvoke printf, strfmt, 'Record #:'
     stdcall getarecord,2
     cinvoke printf, strfmt, 'Record #:'
     stdcall getarecord,3
     cinvoke printf, strfmt, 'Record #:'
     stdcall getarecord,4
     cinvoke printf, strfmt, CRLF

     cinvoke printf, strfmt, 'Delete record no.3 and list remaining records.'
     cinvoke printf, strfmt, CRLF
     stdcall deleterec,3
     stdcall findrecords
     cinvoke printf, strfmt, CRLF

     cinvoke printf, strfmt, 'Update record no. 1 and show it.'
     cinvoke printf, strfmt, CRLF
     stdcall updatearecord,1
     stdcall getarecord,1

     stdcall initdb

.finished:
    invoke  ExitProcess,0

;-------------------------------------------------------------------------------
proc checkduptopic,topic
     cinvoke sqlite3_open, dbname, h3db
     cinvoke wsprintf, sql, findtopic, [topic]
     cinvoke sqlite3_get_table,[h3db],sql,resultp,nrow,ncol,NULL
     mov esi,dword[resultp]
     add esi, 12
     .if dword[nrow] > 0
        mov eax,1
        cinvoke printf, strfmt, 'Duplicate found!'
        cinvoke printf, strfmt, CRLF
     .else
        mov eax,0
     .endif
     cinvoke sqlite3_free_table, dword[resultp]
     cinvoke sqlite3_close,[h3db]
     ret
endp

;-------------------------------------------------------------------------------
proc findrecords
     push  edi esi ebx

     cinvoke sqlite3_open, dbname, h3db
     cinvoke wsprintf, sql, listrecords
     cinvoke sqlite3_get_table,[h3db],sql,resultp,nrow,ncol,NULL
     mov esi,dword[resultp]
     add esi, 12

     ;mov edx, dword[nrow]
     stdcall numrecords, dword[nrow]
     cinvoke printf, strfmt, CRLF
     .while dword[nrow] <> 0

        add esi, 4
        mov edi, esi
        mov ebx, dword[edi]
        mov dword[field0], ebx
        cinvoke printf, strfmt, [field0]
        cinvoke printf, strfmt, CRLF

        add esi, 4
        mov edi, esi
        mov ebx, dword[edi]
        mov dword[field1], ebx
        cinvoke printf, strfmt, [field1]
        cinvoke printf, strfmt, CRLF

        add esi, 4
        mov edi, esi
        mov ebx, dword[edi]
        mov dword[field2], ebx
        cinvoke printf, strfmt, [field2]
        cinvoke printf, strfmt, CRLF

        add esi, 4
        mov edi, esi
        mov ebx, dword[edi]
        mov dword[field3], ebx
        cinvoke printf, strfmt, [field3]
        cinvoke printf, strfmt, CRLF

        dec dword[nrow]
     .endw

     cinvoke sqlite3_free_table, dword[resultp]
     cinvoke sqlite3_close,[h3db]
     pop   ebx esi edi
     ret
endp

;-------------------------------------------------------------------------------
proc updatearecord,recnum
     cinvoke sqlite3_open, dbname, h3db
     cinvoke wsprintf, sql, update, 'topic n','keywords n','notes n',[recnum]
     cinvoke sqlite3_exec, [h3db], sql,0,0,errmsg
     cinvoke sqlite3_close,[h3db]
     ret
endp

;-------------------------------------------------------------------------------
proc getarecord,recnum
     push  edi esi ebx

     cinvoke sqlite3_open, dbname, h3db
     cinvoke wsprintf, sql, getrecord,[recnum]
     cinvoke sqlite3_get_table,[h3db],sql,resultp,nrow,ncol,NULL
     mov esi,dword[resultp]
     add esi, 12

     add esi, 4
     mov edi, esi
     mov ebx, dword[edi]
     mov dword[field0], ebx
     cinvoke printf, strfmt, [field0]
     cinvoke printf, strfmt, CRLF

     add esi, 4
     mov edi, esi
     mov ebx, dword[edi]
     mov dword[field1], ebx
     cinvoke printf, strfmt, [field1]
     cinvoke printf, strfmt, CRLF

     add esi, 4
     mov edi, esi
     mov ebx, dword[edi]
     mov dword[field2], ebx
     cinvoke printf, strfmt, [field2]
     cinvoke printf, strfmt, CRLF

     add esi, 4
     mov edi, esi
     mov ebx, dword[edi]
     mov dword[field3], ebx
     cinvoke printf, strfmt, [field3]
     cinvoke printf, strfmt, CRLF

     cinvoke sqlite3_free_table, dword[resultp]
     cinvoke sqlite3_close,[h3db]
     pop   ebx esi edi
     ret
endp

;-------------------------------------------------------------------------------
proc getsqlitever
     cinvoke sqlite3_libversion
     mov [sqlite_ver], eax
     ret
endp

;-------------------------------------------------------------------------------
proc createdb
     cinvoke sqlite3_open, dbname, h3db
     cmp eax,0
     jnz .errmsg
     cinvoke sqlite3_exec, [h3db], createsql,0,0,errmsg
     cinvoke sqlite3_close,[h3db]
     jmp .done
.errmsg:
     cinvoke printf, strfmt, 'Unable to create database!'
.done:
     ret
endp

;-------------------------------------------------------------------------------
proc initdb
     cinvoke sqlite3_open, dbname, h3db
     cmp eax,0
     jnz .errmsg
     cinvoke sqlite3_exec, [h3db], dropsql,0,0,errmsg
     cmp eax,0
     jnz .errmsg
     cinvoke sqlite3_exec, [h3db], createsql,0,0,errmsg
     cmp eax,0
     jnz .errmsg
     cinvoke sqlite3_close,[h3db]
     jmp .done
.errmsg:
     cinvoke printf, strfmt, 'Unable to initialize database!'
.done:
     ret
endp

;-------------------------------------------------------------------------------
proc addnewrec,f1,f2,f3
     cinvoke sqlite3_open, dbname, h3db
     cinvoke wsprintf,sql, addnew, [f1], [f2], [f3]
     cinvoke sqlite3_exec, [h3db],sql,0,0,errmsg
     cinvoke sqlite3_close, [h3db]
     ret
endp

;-------------------------------------------------------------------------------
proc encodeapostrophe,source,destination
     push  edi esi ebx
     mov esi,[source]
     mov edi,[destination]
     .while byte[esi] <> 0
        .if byte[esi] = 27h
            mov byte[edi],27h
            inc edi
            mov byte[edi],27h
        .endif
     movsb
     .endw
     pop   ebx esi edi
     ret
endp

;-------------------------------------------------------------------------------
proc deleterec,recnum
     cinvoke sqlite3_open, dbname, h3db
     cmp eax,0
     jnz .errmsg
     cinvoke wsprintf, sql, delete, [recnum]
     cinvoke sqlite3_exec, [h3db], sql,0,0,errmsg
     cinvoke sqlite3_close,[h3db]
     jmp .done
.errmsg:
     cinvoke printf, strfmt, 'Unable to delete a record!'
.done:
     ret
endp

;-------------------------------------------------------------------------------
proc numrecords,val
     cinvoke wsprintf,lpout,lpfmt,[val]
     cinvoke printf, strfmt, lpout
     ret
endp

;-------------------------------------------------------------------------------
section '.idata' import data readable writeable
library kernel32, 'KERNEL32.DLL',\
        user32,   'USER32.DLL',\
        msvcrt,   'MSVCRT.DLL',\
        sqlite,   'SQLITE3.DLL'

include 'api\kernel32.inc'
include 'api\user32.inc'

import  msvcrt,\
        fprintf,   'fprintf',\
        printf,    'printf',\
        fgets,     'fgets'

import  sqlite,\
        sqlite3_libversion, 'sqlite3_libversion',\
        sqlite3_open, 'sqlite3_open',\
        sqlite3_exec, 'sqlite3_exec',\
        sqlite3_get_table, 'sqlite3_get_table',\
        sqlite3_free_table,'sqlite3_free_table',\
        sqlite3_close,'sqlite3_close'

;-------------------------------------------------------------------------------

section '.rsrc' resource from 'win32sqlite.res' data readable
; end of file ==================================================================
