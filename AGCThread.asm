INCLUDE Irvine32.inc

option casemap:none

INCLUDE AGCThread.inc
INCLUDE WinAPIs.inc
INCLUDE DSKY.inc

.data

.code
AGCThread PROC lpParam:DWORD
    _AGCLoop:
        INVOKE WaitForMultipleObjects, 2, OFFSET WaitEvents, FALSE, INFINITE
        cmp eax, 1
        je _ExitAGCLoop

        add g_D_R2, 1

        jmp _AGCLoop
    _ExitAGCLoop:
        ret
AGCThread ENDP
END