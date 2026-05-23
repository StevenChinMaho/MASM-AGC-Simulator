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

        .IF g_D_VERB == 6 && g_D_NOUN == 62
            or g_DskyState, MASK D_COMP_ACTY

            add g_D_R2, 1

        .ELSEIF g_D_VERB == 16 && g_D_NOUN == 44
            or g_DskyState, MASK D_COMP_ACTY

            sub g_D_R2, 1
        .ENDIF
        INVOKE Sleep, 500
        and g_DskyState, NOT MASK D_COMP_ACTY

        jmp _AGCLoop
    _ExitAGCLoop:
        ret
AGCThread ENDP
END