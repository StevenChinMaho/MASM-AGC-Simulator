INCLUDE Irvine32.inc
.386
.model flat,stdcall
ExitProcess PROTO, dwExitCode:DWORD

; ========= 引入終端 CodePage 設定 =========
SetConsoleOutputCP PROTO, wCodePageID:DWORD
; ========================================

ExecAGCThread PROTO, lpParam:DWORD

INCLUDE DSKY.inc
INCLUDE main.inc

.data
    dskyUI BYTE "┌───────────────────────────────────────────────────────┐", 0Dh, 0Ah
           BYTE "├───────────────────────────┬───────────────────────────┤", 0Dh, 0Ah
           BYTE "│ UPLINK ACTY |    TEMP     │ ┌───────────────────────┐ │", 0Dh, 0Ah
           BYTE "│             |             │ │    COMP       PROG    │ │", 0Dh, 0Ah
           BYTE "│   NO ATT    | GIMBAL LOCK │ │    ACTY    [     ]    │ │", 0Dh, 0Ah
           BYTE "│             |             │ │                       │ │", 0Dh, 0Ah
           BYTE "│    STBY     |    PROG     │ │    VERB       NOUN    │ │", 0Dh, 0Ah
           BYTE "│             |             │ │    [     ] [     ]    │ │", 0Dh, 0Ah
           BYTE "│   KEY REL   |   RESTART   │ │  ___________________  │ │", 0Dh, 0Ah
           BYTE "│             |             │ │                       │ │", 0Dh, 0Ah
           BYTE "│   OPR ERR   |   TRACKER   │ │    + [           ]    │ │", 0Dh, 0Ah
           BYTE "│             |             │ │                       │ │", 0Dh, 0Ah
           BYTE "│             |     ALT     │ │    + [           ]    │ │", 0Dh, 0Ah
           BYTE "│             |             │ │                       │ │", 0Dh, 0Ah
           BYTE "│             |     VEL     │ │    + [           ]    │ │", 0Dh, 0Ah
           BYTE "│             |             │ └───────────────────────┘ │", 0Dh, 0Ah
           BYTE "├───────────────────────────┴───────────────────────────┤", 0Dh, 0Ah
           BYTE "├───────────────────────────────────────────────────────┤", 0Dh, 0Ah
           BYTE "│                                                       │", 0Dh, 0Ah
           BYTE "│        ┌     ┐ ┌     ┐ ┌     ┐ ┌     ┐ ┌     ┐        │", 0Dh, 0Ah
           BYTE "│┌      ┐│  +  │ │  7  │ │  8  │ │  9  │ │ CLR │┌      ┐│", 0Dh, 0Ah
           BYTE "││ VERB │└     ┘ └     ┘ └     ┘ └     ┘ └     ┘│ ENTR ││", 0Dh, 0Ah
           BYTE "│└      ┘┌     ┐ ┌     ┐ ┌     ┐ ┌     ┐ ┌     ┐└      ┘│", 0Dh, 0Ah
           BYTE "│        │  -  │ │  4  │ │  5  │ │  6  │ │ PRO │        │", 0Dh, 0Ah
           BYTE "│┌      ┐└     ┘ └     ┘ └     ┘ └     ┘ └     ┘┌      ┐│", 0Dh, 0Ah
           BYTE "││ NOUN │┌     ┐ ┌     ┐ ┌     ┐ ┌     ┐ ┌     ┐│ RSET ││", 0Dh, 0Ah
           BYTE "│└      ┘│  0  │ │  1  │ │  2  │ │  3  │ │ KER │└      ┘│", 0Dh, 0Ah
           BYTE "│        └     ┘ └     ┘ └     ┘ └     ┘ └     ┘        │", 0Dh, 0Ah
           BYTE "├───────────────────────────────────────────────────────┤", 0Dh, 0Ah
           BYTE "└───────────────────────────────────────────────────────┘", 0

    DescriptionString BYTE "This is a simple DSKY simulation.", 0
    
    qwDueTime   QWORD -20000000 ; 2秒 (20,000,000 * 100ns = 2s)
    
.data?
    hTimer      DWORD ?
    hExitEvent  DWORD ?
    hThread     DWORD ?
    WaitEvents  DWORD 2 DUP(?)

.code

pikachu:
    ; =========== 畫面初始化 ============
    INVOKE SetConsoleOutputCP, 65001            ; 設定輸出使用 UTF-8 編碼

    mov edx, OFFSET dskyUI
    call WriteString

    INVOKE RenderDSKY

    mov dx, ((2 SHL 8) OR 60)
    call Gotoxy
    mov edx, OFFSET DescriptionString
    call WriteString
    ; =================================
    call ReadChar
    ; ========== 建立計時器與事件，並啟動模擬執行緒 ==========
    INVOKE CreateWaitableTimer, NULL, FALSE, NULL
    mov hTimer, eax
    mov WaitEvents[TYPE WaitEvents * 0], eax
    INVOKE SetWaitableTimer, hTimer, OFFSET qwDueTime, 100, NULL, NULL, FALSE

    INVOKE CreateEvent, NULL, TRUE, FALSE, NULL
    mov hExitEvent, eax
    mov WaitEvents[TYPE WaitEvents * 1], eax

    INVOKE CreateThread, NULL, 0, OFFSET ExecAGCThread, NULL, 0, NULL
    mov hThread, eax
    ; =========================================================

    mov g_D_R1, 0
    mov g_D_R2, 20
    mov g_DskyState, 0
    _MainLoop:
        INVOKE RenderDSKY
        call ReadKey
        jz ContinueLoop           ; 如果沒有按鍵輸入，繼續等待

        cmp al, VK_ESCAPE
        je ExitLoop

        cmp al, VK_RETURN
        jne ContinueLoop
        inc g_D_R1

ContinueLoop:
        INVOKE Sleep, 100
        jmp _MainLoop
    
ExitLoop:

    mov g_D_PROG, 88
    mov g_D_VERB, 88
    mov g_D_NOUN, 88
    mov g_D_R1, 88888
    mov g_D_R2, 88888
    mov g_D_R3, 88888

    or g_DskyState, 1111111111111b

    INVOKE RenderDSKY

    INVOKE SetEvent, hExitEvent
    INVOKE WaitForSingleObject, hThread, INFINITE
    INVOKE CloseHandle, hTimer
    INVOKE CloseHandle, hExitEvent
    INVOKE CloseHandle, hThread

    INVOKE ExitProcess,0

ExecAGCThread PROC lpParam:DWORD
    _AGCLoop:
        INVOKE WaitForMultipleObjects, 2, OFFSET WaitEvents, FALSE, INFINITE
        cmp eax, 1
        je _ExitAGCLoop

        add g_D_R2, 1

        jmp _AGCLoop
    _ExitAGCLoop:
        ret
ExecAGCThread ENDP

END pikachu
