format PE console
entry start

include 'win32a.inc'

;--------------------------------------------------------------------------
section '.data' data readable writable

        strVecSize   db 'size of vector? ', 0
        strIncorSize db 'Incorrect size of vector = %d', 10, 0
        strVecElemI  db '[%d]? ', 0
        strScanInt   db '%d', 0
        strVecElemOut  db '[%d] = %d', 10, 0
        strNumInput db 'X? ', 0
        strIncorX db 'Incorrect X = %d', 10, 0
        strArrA   db 'A:', 10, 0
        strArrB   db 'B:', 10, 0

        vec_size     dd 0
        res_vec_size dd 0
        i            dd ?
        tmp          dd ?
        tmp1          dd ?
        tmp2          dd ?
        tmpStack     dd ?
        vec          rd 100
        resVec       rd 100
        x            dd 0
        modulus      dd 0
        dividend     dd 0
;--------------------------------------------------------------------------
section '.code' code readable executable
start:
; 1) vector input
        call VectorInput
; 2) test vector out
        call VectorOut
; 3) get X
        call InputX
; 4) make new array
        call MakeNewArray
; 5) print new array
        call res_VectorOut
finish:
        call [getch]

        push 0
        call [ExitProcess]

;--------------------------------------------------------------------------
VectorInput:
        push strVecSize
        call [printf]
        add esp, 4

        push vec_size
        push strScanInt
        call [scanf]
        add esp, 8

        mov eax, [vec_size]
        cmp eax, 0
        jg  getVector
; fail size
        push vec_size
        push strIncorSize
        call [printf]
        push 0
        ;call [ExitProcess]
        jmp finish
; else continue...
getVector:
        xor ecx, ecx            ; ecx = 0
        mov ebx, vec            ; ebx = &vec
getVecLoop:
        mov [tmp], ebx
        cmp ecx, [vec_size]
        jge endInputVector       ; to end of loop

        ; input element
        mov [i], ecx
        push ecx
        push strVecElemI
        call [printf]
        add esp, 8

        push ebx
        push strScanInt
        call [scanf]
        add esp, 8

        mov ecx, [i]
        inc ecx
        mov ebx, [tmp]
        add ebx, 4
        jmp getVecLoop
endInputVector:
        ret
;--------------------------------------------------------------------------
VectorOut:
        mov [tmpStack], esp
        push strArrA
        call [printf]
        mov esp, [tmpStack]

        mov [tmpStack], esp
        xor ecx, ecx            ; ecx = 0
        mov ebx, vec            ; ebx = &vec
putVecLoop:
        mov [tmp], ebx
        cmp ecx, [vec_size]
        je endOutputVector      ; to end of loop
        mov [i], ecx

        ; output element
        push dword [ebx]
        push ecx
        push strVecElemOut
        call [printf]

        mov ecx, [i]
        inc ecx
        mov ebx, [tmp]
        add ebx, 4
        jmp putVecLoop
endOutputVector:
        mov esp, [tmpStack]
        ret
;--------------------------------------------------------------------------
InputX:
        ;print
        push strNumInput
        call [printf]
        add esp, 4

        ;input
        push x
        push strScanInt
        call [scanf]
        add esp, 8

        ; x == int?
        mov eax, [x]
        cmp eax, 0
        ; yes
        jne absX
        ; no

        ; fail X
        push x
        push strIncorX
        call [printf]
        push 0
        ;call [ExitProcess]
        jmp finish

absX:
        ; x < 0 ?
        cmp eax, 0
        ; no
        jg endInputX
        ; yes
        neg eax
        mov [x], eax

endInputX:
        ret


;--------------------------------------------------------------------------
MakeNewArray:
        ; i
        xor esi, esi            ; i = 0
        ; j
        xor edi, edi            ; j = 0
        mov eax, vec            ; eax = &vec
        mov ebx, resVec         ; ebx = &resVec
        ; for (i = 0; i < oldArray.Size; i++)
arrLoop:
        mov [tmp1], eax
        mov [tmp2], ebx
        ; i < oldArray.Size?
        cmp esi, [vec_size]
        ; Yes
        jge endMNA
        ; No

        mov ecx, dword[eax]
        mov [dividend], ecx
        call Modulus
        mov edx, [modulus]
        ; oldArray[i] % x == 0 ?
        cmp edx, 0
        ; No
        jne loopNext
        ; Yes
        mov eax, [tmp1]
        mov ebx, [tmp2]
        mov ecx, dword[eax]
        mov dword[ebx], ecx
        ; j++
        inc edi
        ; newArray.Next
        add ebx, 4
loopNext:
        ; i++
        inc esi
        mov eax, [tmp1]
        ; oldArray.Next
        add eax, 4
        jmp arrLoop
endMNA:
        ; newArray.Size = j
        mov [res_vec_size], edi
        ret
;--------------------------------------------------------------------------
Modulus:
    ; save registers
    push eax
    push ebx
    push ecx
    push edx

    ; eax % ebx = edx
    mov edx, 0
    mov eax, [dividend]
    mov ebx, [x]
    div ebx

    ; modulus = edx
    mov [modulus], edx

    ; load registers
    pop edx
    pop ecx
    pop ebx
    pop eax

    ret

;--------------------------------------------------------------------------
res_VectorOut:
        mov [tmpStack], esp
        push strArrB
        call [printf]
        mov esp, [tmpStack]

        mov [tmpStack], esp
        xor ecx, ecx            ; ecx = 0
        mov ebx, resVec         ; ebx = &resVec
res_putVecLoop:
        mov [tmp], ebx
        cmp ecx, [res_vec_size]
        je res_endOutputVector      ; to end of loop
        mov [i], ecx

        ; output element
        push dword [ebx]
        push ecx
        push strVecElemOut
        call [printf]

        mov ecx, [i]
        inc ecx
        mov ebx, [tmp]
        add ebx, 4
        jmp res_putVecLoop
res_endOutputVector:
        mov esp, [tmpStack]
        ret

;-------------------------------third act - including HeapApi--------------------------
                                                 
section '.idata' import data readable
    library kernel, 'kernel32.dll',\
            msvcrt, 'msvcrt.dll',\
            user32,'USER32.DLL'

include 'api\user32.inc'
include 'api\kernel32.inc'
    import kernel,\
           ExitProcess, 'ExitProcess',\
           HeapCreate,'HeapCreate',\
           HeapAlloc,'HeapAlloc'
  include 'api\kernel32.inc'
    import msvcrt,\
           printf, 'printf',\
           scanf, 'scanf',\
           getch, '_getch'