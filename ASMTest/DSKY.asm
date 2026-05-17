INCLUDE Irvine32.inc
.386
.model flat, stdcall
option casemap:none

INCLUDE DSKY.inc

.data

    szUplink   BYTE "UPLINK ACTY", 0
    szNoAtt    BYTE "  NO ATT   ", 0
    szStby     BYTE "   STBY    ", 0
    szKeyRel   BYTE "  KEY REL  ", 0
    szOprErr   BYTE "  OPR ERR  ", 0

    szTemp     BYTE "   TEMP    ", 0
    szGimbal   BYTE "GIMBAL LOCK", 0
    szProg     BYTE "   PROG    ", 0
    szRestart  BYTE "  RESTART  ", 0
    szTracker  BYTE "  TRACKER  ", 0
    szAlt      BYTE "    ALT    ", 0
    szVel      BYTE "    VEL    ", 0

    szComp     BYTE "COMP", 0
    szActy     BYTE "ACTY", 0

    g_DskyState DskyStateRecord <0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1>
    s_DskyCurrentState DskyStateRecord <>

.code

; ==============================================================================
; 巨集：CheckAndDrawLight
; 功能：比對差異遮罩，若有變動則移動游標、改變顏色並重新印出文字
; 參數：LightMask (狀態遮罩), posX (X座標), posY (Y座標), szText (字串變數名), LightColor (燈光顏色)
; ==============================================================================
CheckAndDrawLight MACRO LightMask, posX, posY, szText, LightColor
    LOCAL SkipDraw, SetOn, DrawText
    
    test esi, LightMask        ; ESI 裝的是差異(Delta)。檢查這個燈是否有變動
    jz SkipDraw                ; 沒變動 -> 直接跳過
    
    test edi, LightMask        ; EDI 裝的是新狀態。檢查現在是要亮還是暗
    jnz SetOn                  ; 如果是 1，跳去設定亮色
    
    ; === 設定暗色狀態 (熄滅) ===
    mov eax, 8 * 16                 ; 預設燈色
    call SetTextColor
    jmp DrawText

SetOn:
    ; === 設定亮色狀態 (點亮) ===
    mov eax, LightColor                ; 燈號亮起
    call SetTextColor

DrawText:
    ; 移動游標到指定座標
    mov dl, posX
    mov dh, posY
    call Gotoxy
    
    ; 印出燈號文字
    mov edx, OFFSET szText
    call WriteString
    
SkipDraw:
ENDM

RenderDSKY PROC
    pushad

    mov edi, g_DskyState
    mov esi, s_DskyCurrentState

    xor esi, edi
    jz _RenderDone

    ; 2. 使用巨集依序檢查並渲染每一個燈號
    ; 格式：CheckAndDrawLight  <MASK>      <X> <Y> <Text> <LightColor>

    ; === 左欄燈號 (X=2) ===
    CheckAndDrawLight MASK L_UPLINK_ACTY,  2,  2, szUplink, 15 * 16
    CheckAndDrawLight MASK L_NO_ATT,       2,  4, szNoAtt, 15 * 16
    CheckAndDrawLight MASK L_STBY,         2,  6, szStby, 15 * 16
    CheckAndDrawLight MASK L_KEY_REL,      2,  8, szKeyRel, 15 * 16
    CheckAndDrawLight MASK L_OPR_ERR,      2,  10, szOprErr, 15 * 16

    ; === 右欄燈號 (X=16) ===
    CheckAndDrawLight MASK L_TEMP,        16,  2, szTemp, 14 * 16
    CheckAndDrawLight MASK L_GIMBAL_LOCK, 16,  4, szGimbal, 14 * 16
    CheckAndDrawLight MASK L_PROG,        16,  6, szProg, 14 * 16
    CheckAndDrawLight MASK L_RESTART,     16,  8, szRestart, 14 * 16
    CheckAndDrawLight MASK L_TRACKER,     16, 10, szTracker, 14 * 16
    CheckAndDrawLight MASK L_ALT,         16, 12, szAlt, 14 * 16
    CheckAndDrawLight MASK L_VEL,         16, 14, szVel, 14 * 16

    ; === 運算燈號 (X=34) ===
    CheckAndDrawLight MASK D_COMP_ACTY,   34, 3, szComp, 14 * 16
    CheckAndDrawLight MASK D_COMP_ACTY,   34, 4, szActy, 14 * 16

    ; 更新完畢，將私有狀態同步為最新狀態
    mov s_DskyCurrentState, edi

_RenderDone:
    ; 復原預設顏色
    mov eax, 7
    call SetTextColor

    ; 將游標移到畫面右下角
    mov dl, 57
    mov dh, 29
    call Gotoxy

    popad
    ret
RenderDSKY ENDP

END