IFNDEF DSKY_INC
DSKY_INC EQU 1

IFNDEF TRUE
    TRUE  EQU 1
ENDIF

IFNDEF FALSE
    FALSE EQU 0
ENDIF

IFNDEF EMPTY
    EMPTY EQU 7FFFFFFFh
ENDIF

lightOff EQU ((gray * 16) + black)
whiteLight EQU ((white * 16) + black)
yellowLight EQU ((yellow * 16) + black)
greenText EQU ((black * 16) + lightGreen)

RenderDSKY PROTO

; 右側資訊面板 API
InitInfoPanel PROTO
RenderTimers PROTO

ENDIF