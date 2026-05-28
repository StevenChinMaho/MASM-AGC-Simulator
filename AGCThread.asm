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

        or g_DskyState, MASK D_COMP_ACTY
        
        INVOKE Sleep, 500
        and g_DskyState, NOT MASK D_COMP_ACTY

        jmp _AGCLoop
    _ExitAGCLoop:
        ret
AGCThread ENDP
END