INCLUDE Irvine32.inc
.386
.model flat,stdcall
ExitProcess PROTO, dwExitCode:DWORD

INCLUDE DSKY.inc

SetConsoleOutputCP PROTO, wCodePageID:DWORD

.data
    dskyUI BYTE "┌───────────────────────────────────────────────────────┐", 0Dh, 0Ah
           BYTE "├───────────────────────────┬───────────────────────────┤", 0Dh, 0Ah
           BYTE "│ UPLINK ACTY |    TEMP     │ ┌───────────────────────┐ │", 0Dh, 0Ah
           BYTE "│             |             │ │   COMP        PROG    │ │", 0Dh, 0Ah
           BYTE "│   NO ATT    | GIMBAL LOCK │ │   ACTY     [     ]    │ │", 0Dh, 0Ah
           BYTE "│             |             │ │                       │ │", 0Dh, 0Ah
           BYTE "│    STBY     |    PROG     │ │   VERB        NOUN    │ │", 0Dh, 0Ah
           BYTE "│             |             │ │   [     ]  [     ]    │ │", 0Dh, 0Ah
           BYTE "│   KEY REL   |   RESTART   │ │  ___________________  │ │", 0Dh, 0Ah
           BYTE "│             |             │ │                       │ │", 0Dh, 0Ah
           BYTE "│   OPR ERR   |   TRACKER   │ │   + [           ]     │ │", 0Dh, 0Ah
           BYTE "│             |             │ │                       │ │", 0Dh, 0Ah
           BYTE "│             |     ALT     │ │   + [           ]     │ │", 0Dh, 0Ah
           BYTE "│             |             │ │                       │ │", 0Dh, 0Ah
           BYTE "│             |     VEL     │ │   + [           ]     │ │", 0Dh, 0Ah
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
           BYTE "└───────────────────────────────────────────────────────┘", 0Dh, 0Ah
           BYTE 0

.code

main PROC
    INVOKE SetConsoleOutputCP, 65001
    mov edx, OFFSET dskyUI
    call WriteString

    mov g_DskyState, 1111111111111b
    INVOKE RenderDSKY

    mov g_DskyState, 1

    mov ecx, 13

_MainLoop:
    INVOKE RenderDSKY

    shl g_DskyState, 1
  
    mov eax, 1000
    call Delay
    loop _MainLoop

    INVOKE ExitProcess,0
main ENDP
END main
