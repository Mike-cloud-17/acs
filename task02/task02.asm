; Задание 2, Вариант 8
; Щербаков Дмитрий Александрович
; Разработать программу, которая вводит одномерный массив A[N], формирует из элементов массива A новый массив B по правилам, указанным в таблице, и выводит его. Память под массивы может выделяться как статически, так и динамически по выбору разработчика.
; Разбить решение задачи на функции следующим образом:
; - Ввод и вывод массивов оформить как подпрограммы.
; - Выполнение задания по варианту оформить как процедуру
; - Организовать вывод как исходного, так и сформированного массивов
; Указанные процедуры могут использовать данные напрямую (имитация процедур без параметров). Имитация работы с параметрами также допустима.
; Массив B из элементов B[i]=A+5, если A[i]>5; B[i]=A-5, если A[i]<5; B[i]=0, иначе
format PE console
entry start

include 'INCLUDE\MACRO\import32.inc'
include 'INCLUDE\MACRO\proc32.inc'

;--------------------------------------------------------------------------
section '.data' data readable writable
        strVecSize   db 'N:', 0
        strIncorSize db 'Input invalid: %d', 10, 0
        strVecElemI  db 'A[%d]:', 0
        strPrintInt  db '%d%c', 0
        strScanInt   db '%d', 0

;--------------------------------------------------------------------------
section '.code' code readable executable
start:
        push ebp
        mov ebp, esp
        sub esp, 12 ; int* vec, int n, int* result

        lea eax, [ebp - 4]
        push eax
        call VectorInput
        add esp, 4
        mov [ebp - 8], eax ; n = VectorInput(&vec)

        push DWORD [ebp - 4]
        push DWORD [ebp - 8]
        call VectorTransform
        add esp, 8
        mov [ebp - 12], eax ; result = VectorTransform(n, vec)

        push DWORD [ebp - 4]
        push DWORD [ebp - 8]
        call VectorOutput ; VectorOutput(n, vec)
        add esp, 8

        push DWORD [ebp - 12]
        push DWORD [ebp - 8]
        call VectorOutput ; VectorOutput(n, result)
        add esp, 8

        call [getch]
        add esp, 8
        pop ebp
        push 0
        call [exit]

;--------------------------------------------------------------------------
VectorInput: ; int VectorInput(int** vec)
        push ebp
        mov ebp, esp
        sub esp, 12 ; int n, int i, int* curr

        ; print_N:
             push strVecSize
             call [printf] ; printf("N:")
             add esp, 4
             jmp input_size

        invalid_size:
                push DWORD [ebp - 4]
                push strIncorSize
                call [printf] ; printf("Input invalid: %d", n)
                add esp, 8

        input_size:
                lea eax, [ebp - 4]
                push eax
                push strScanInt
                call [scanf] ; scanf("%d", &n)
                add esp, 8
                mov eax, [ebp - 4]
                cmp eax, 0
                jl invalid_size ; if (n < 0)

        ; alloc_vector:
                push DWORD 4
                push DWORD [ebp - 4]
                call [calloc]
                add esp, 8
                mov ebx, [ebp + 8]
                mov [ebx], eax ; *vec = calloc(n, 4)
                mov DWORD [ebp - 8], 0 ; i = 0
                 mov [ebp - 12], eax ; curr = vec

        loop0:
                mov eax, [ebp - 8]
                cmp eax, [ebp - 4] ; while i < n
                jge end_loop0

                push DWORD [ebp - 8]
                push strVecElemI
                call [printf] ; printf("A[%d]: ", i)
                add esp, 8

                push DWORD [ebp - 12]
                push strScanInt
                call [scanf] ; scanf("%d", curr)
                add esp, 8

                add DWORD [ebp - 12], 4 ; curr += 1)
                add DWORD [ebp - 8], 1 ; i += 1
                jmp loop0
        end_loop0:

        mov eax, DWORD [ebp - 4] ; return n

        add esp, 12 ; clean stack
        pop ebp
        ret

;--------------------------------------------------------------------------
VectorTransform: ; int* VectorTransform(int n, int* vec)
        push ebp
        mov ebp, esp
        sub esp, 8 ; int i, int* result

        push 4
        push DWORD [ebp + 8]
        call [calloc]
        add esp, 8

        mov [ebp - 8], eax ; result = calloc(n, 4)
        mov DWORD [ebp - 4], 0 ; i = 0

        loop2:
                mov eax, [ebp - 4]
                cmp eax, [ebp + 8] ; while (i < n)
                jge end_loop2
                add DWORD [ebp - 4], 1 ; i += 1

                mov ebx, 4
                mul ebx
                mov ebx, eax
                add ebx, [ebp - 8] ; ebx = result + i
                add eax, [ebp + 12] ; eax = vec + i

                cmp DWORD [eax], 5
                jg more
                jle less

                more:
                        mov eax, [eax]
                        mov [ebx], eax
                        add DWORD [ebx], 5 ; result[i] = vec[i] + 5
                        jmp loop2
                less:
                        cmp DWORD [eax], -5
                        jge zero
                        mov eax, [eax]
                        mov [ebx], eax
                        sub DWORD [ebx], 5 ; result[i] = vec[i] - 5
                        jmp loop2
                zero:
                        mov DWORD [ebx], 0; result[i] = 0
                        jmp loop2
        end_loop2:

        mov eax, DWORD [ebp - 8]

        add esp, 8
        pop ebp
        ret

;--------------------------------------------------------------------------
VectorOutput: ; void VectorOutput(int n, int* vec)
        mov ecx, DWORD [esp + 4] ; ecx = n
        mov ebx, DWORD [esp + 8] ; ebx = vec
        loop1:
                cmp ecx, 1 ; while ecx >= 1
                mov eax, ' '
                jg not_last
                jl end_loop1
                mov eax, 10 ; if last then end with \n
        not_last:
                push ecx
                push eax
                push DWORD [ebx]
                push strPrintInt
                call [printf]
                add esp, 12
                pop ecx

                add ebx, 4
                sub ecx, 1
                jmp loop1
        end_loop1:
        ret

;--------------------------------------------------------------------------
section '.idata' import data readable
    library msvcrt, 'msvcrt.dll'
    import msvcrt,\
           printf, 'printf',\
           scanf, 'scanf',\
           getch, '_getch',\
           calloc, 'calloc',\
           exit, 'exit'