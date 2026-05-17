INCLUDE Irvine32.inc
.386
.model flat,stdcall
ExitProcess PROTO, dwExitCode:DWORD

; ========= 引入終端 CodePage 設定 =========
SetConsoleOutputCP PROTO, wCodePageID:DWORD
; ========================================

INCLUDE DSKY.inc

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

    cmdMode BYTE "mode con: cols=80 lines=35", 0  ; 設定寬度80，高度35
.code

main PROC
    ; =========== 畫面初始化 ============
    INVOKE SetConsoleOutputCP, 65001            ; 設定輸出使用 UTF-8 編碼

    mov edx, OFFSET dskyUI
    call WriteString

    INVOKE RenderDSKY
    ; =================================

    mov g_DskyState, 1
    mov g_D_PROG, 11
    mov g_D_VERB, 22
    mov g_D_NOUN, 33
    mov g_D_R1, 5
    mov g_D_R2, 99995
    mov g_D_R3, -99995

    mov ecx, 13
_MainLoop:
    INVOKE RenderDSKY

    shl g_DskyState, 1
    sub g_D_R1, 1
    inc g_D_R2
    dec g_D_R3
    inc g_D_PROG
  
    mov eax, 1000
    call Delay
    loop _MainLoop

    mov g_D_PROG, 88
    mov g_D_VERB, 88
    mov g_D_NOUN, 88
    mov g_D_R1, 88888
    mov g_D_R2, 88888
    mov g_D_R3, 88888

    or g_DskyState, 1111111111111b

    INVOKE RenderDSKY

    INVOKE ExitProcess,0
main ENDP
END main
