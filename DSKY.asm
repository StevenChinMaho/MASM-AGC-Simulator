INCLUDE Irvine32.inc

option casemap:none

INCLUDE DSKY.inc
INCLUDE Globals.inc

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

    s_DskyCurrentState DskyStateRecord <>

    s_D_PROG   DWORD 88
    s_D_VERB   DWORD 88
    s_D_NOUN   DWORD 88
    s_D_R1     DWORD 88888
    s_D_R2     DWORD 88888
    s_D_R3     DWORD 88888
.code

; ==============================================================================
; 巨集: CheckAndDrawLight
; 功能: 比對差異遮罩，若有變動則移動游標、改變顏色並重新印出文字
; 參數: LightMask (狀態遮罩), posX (X座標), posY (Y座標), szText (字串變數名), LightColor (燈光顏色)
; ==============================================================================
CheckAndDrawLight MACRO LightMask, posX, posY, szText, LightColor
    LOCAL SkipDraw, SetOn, DrawText
    
    test esi, LightMask        ; ESI 裝的是差異(Delta)。檢查這個燈是否有變動
    jz SkipDraw                ; 沒變動 -> 直接跳過
    
    test edi, LightMask        ; EDI 裝的是新狀態。檢查現在是要亮還是暗
    jnz SetOn                  ; 如果是 1，跳去設定亮色
    
    ; === 設定暗色狀態 (熄滅) ===
    mov eax, lightOff          ; 預設燈色 (黑字暗灰底色)
    call SetTextColor
    jmp DrawText

SetOn:
    ; === 設定亮色狀態 (點亮) ===
    mov eax, LightColor        ; 燈號亮起
    call SetTextColor

DrawText:
    ; 移動游標到指定座標
    mov dx, ((posY) SHL 8) OR posX
    call Gotoxy
    
    ; 印出燈號文字
    mov edx, OFFSET szText
    call WriteString
    
SkipDraw:
ENDM

; ==============================================================================
; 巨集: CheckAndDrawNumber
; 功能: 比對差異遮罩，若有變動則移動游標、改變顏色並重新印出數字
; 參數: currentNum (目前數值), newNum (新數值), posX (X座標), posY (Y座標), digit (位數), isSigned (是否有符號)
; ==============================================================================
CheckAndDrawNumber MACRO currentNum, newNum, posX, posY, digit, isSigned
    LOCAL SkipDraw, DrawNumbers, ClearDigits, IsPositive, EndSigned, ExtractLoop, DrawDigits
    
    mov eax, newNum
    cmp eax, currentNum         ; 檢查這個數字是否有變動
    jz SkipDraw                 ; 沒變動 -> 直接跳過
    
    mov currentNum, eax         ; 更新目前數值為新數值

    ; === 如果新數值是 EMPTY，清除舊數字 ===
    cmp eax, EMPTY
    jne DrawNumbers

    mov al, ' '
IF isSigned
    mov dx, ((posY) SHL 8) OR (posX - 4)        ; dl = posX - 4, dh = posY
    call Gotoxy

    call WriteChar
ENDIF
    mov dx, ((posY) SHL 8) OR posX       ; dl = posX, dh = posY
    
    mov ecx, digit
    ClearDigits:
        call Gotoxy
        call WriteChar
        add dl, 2                       ; 移動到下位的數字
        loop ClearDigits

    jmp SkipDraw                        ; 如果新數值是 EMPTY，就不畫數字

DrawNumbers:
    ; 如果有符號位，先輸出符號
IF isSigned
    mov dx, ((posY) SHL 8) OR (posX - 4)        ; dl = posX - 4, dh = posY
    call Gotoxy

    ;mov eax, newNum
    cmp eax, 0
    jge IsPositive

    push eax
    mov al, '-'             ; 顯示負號
    call WriteChar
    pop eax
    neg eax

    jmp EndSigned

IsPositive:
    push eax
    mov al, '+'             ; 顯示正號
    call WriteChar
    pop eax
EndSigned:
ENDIF

    mov edi, 0CCCCCCCDh         ; 這是除以 10 的乘法反數 (2^35 / 10)，用來快速除以 10
    mov ecx, digit
    ExtractLoop:
        mov esi, eax
        
        mul edi                 ; EDX:EAX = EAX * 0CCCCCCCDh
        shr edx, 3              ; edx = (Quotient) esi / 10

        lea ebx, [edx*4 + edx]  ; ebx = (Quotient) * 5
        add ebx, ebx			; ebx = (Quotient) * 10 
        sub esi, ebx            ; esi = Remainder = eax - Quotient * 10

        push esi                ; 暫存這一位的數字

        ; === 準備下一輪除以 10 ===
        mov eax, edx            ; eax = Quotient

        loop ExtractLoop


    mov ecx, digit              ; 重新載入位數計數器
    mov dx, ((posY) SHL 8) OR posX			    ; 基準座標 (dl = posX, dh = posY)
    DrawDigits:
        call Gotoxy

        pop eax                 ; 取出一位數字
        add al, '0'             ; 轉為 ASCII 字元
        call WriteChar

        add dl, 2               ; 移動到下位的數字
        loop DrawDigits          

SkipDraw:
ENDM

RenderDSKY PROC
    pushad

    mov edi, g_DskyState

    ; === 閃爍魔法 (Flash Mask Logic) ===
    cmp g_MasterBlink, 0
    jne _SkipFlashMask          ; 如果節拍是 1 (亮)，什麼都不用做，維持原樣
    
    ; 如果節拍是 0 (暗)，我們要把被設定為「閃爍」的燈強制熄滅
    mov eax, g_DskyFlashState
    not eax                     ; 把 1 變 0 (代表這些燈這回合不能亮)
    and edi, eax                ; 套用到目前的顯示狀態上
_SkipFlashMask:
    ; ===================================

    mov esi, s_DskyCurrentState

    xor esi, edi
    jz _RenderNumbers

    ; 使用巨集依序檢查並渲染每一個燈號
    ; 格式: CheckAndDrawLight  <MASK>      <X> <Y> <Text> <LightColor>

    ; === 左欄燈號 (X=2) ===
    CheckAndDrawLight MASK L_UPLINK_ACTY,  2,  2, szUplink, whiteLight
    CheckAndDrawLight MASK L_NO_ATT,       2,  4, szNoAtt, whiteLight
    CheckAndDrawLight MASK L_STBY,         2,  6, szStby, whiteLight
    CheckAndDrawLight MASK L_KEY_REL,      2,  8, szKeyRel, whiteLight
    CheckAndDrawLight MASK L_OPR_ERR,      2,  10, szOprErr, whiteLight

    ; === 右欄燈號 (X=16) ===
    CheckAndDrawLight MASK L_TEMP,        16,  2, szTemp, yellowLight
    CheckAndDrawLight MASK L_GIMBAL_LOCK, 16,  4, szGimbal, yellowLight
    CheckAndDrawLight MASK L_PROG,        16,  6, szProg, yellowLight
    CheckAndDrawLight MASK L_RESTART,     16,  8, szRestart, yellowLight
    CheckAndDrawLight MASK L_TRACKER,     16, 10, szTracker, yellowLight
    CheckAndDrawLight MASK L_ALT,         16, 12, szAlt, yellowLight
    CheckAndDrawLight MASK L_VEL,         16, 14, szVel, yellowLight

    ; === 運算燈號 (X=34) ===
    CheckAndDrawLight MASK D_COMP_ACTY,   35, 3, szComp, yellowLight
    CheckAndDrawLight MASK D_COMP_ACTY,   35, 4, szActy, yellowLight

    ; 更新完畢，將私有狀態同步為最新狀態
    mov s_DskyCurrentState, edi

_RenderNumbers:
    ; 設定顏色 (亮綠色)
    mov eax, greenText 
    call SetTextColor

    ; 使用巨集依序檢查並渲染每一個數字
    ; 格式: CheckAndDrawNumber <currentNum> <newNum> <posX> <posY> <digit> <isSigned>
    CheckAndDrawNumber s_D_PROG, g_D_PROG,  45, 4, 2, FALSE

    ; ==========================================
    ; 【新增】處理 VERB 閃爍
    ; ==========================================
    mov eax, g_D_VERB
    cmp g_FlashVerb, 1          ; 如果沒有開啟閃爍
    jne _DrawVerb               ; -> 正常畫
    cmp g_MasterBlink, 0        ; 如果開啟了，但現在是亮(1)的節拍
    jne _DrawVerb               ; -> 正常畫
    mov eax, EMPTY              ; 否則現在是暗(0)的節拍 -> 換成空白
_DrawVerb:
    CheckAndDrawNumber s_D_VERB, eax,  37, 7, 2, FALSE

    ; ==========================================
    ; 【新增】處理 NOUN 閃爍
    ; ==========================================
    mov eax, g_D_NOUN
    cmp g_FlashNoun, 1
    jne _DrawNoun
    cmp g_MasterBlink, 0
    jne _DrawNoun
    mov eax, EMPTY
_DrawNoun:
    CheckAndDrawNumber s_D_NOUN, eax,  45, 7, 2, FALSE

    CheckAndDrawNumber s_D_R1, g_D_R1,      39, 10, 5, TRUE
    CheckAndDrawNumber s_D_R2, g_D_R2,      39, 12, 5, TRUE
    CheckAndDrawNumber s_D_R3, g_D_R3,      39, 14, 5, TRUE

_RenderDone:
    ; 復原預設顏色
    mov eax, 7
    call SetTextColor

    ; 將游標移到畫面右下角
    mov dx, ((29) SHL 8) OR 57
    call Gotoxy

    popad
    ret
RenderDSKY ENDP

; ==============================================================================
; SyncActiveToDisplay
; 功能: 將系統真實狀態 (Model) 強制覆寫到顯示變數 (View) 上
; ==============================================================================
SyncActiveToDisplay PROC USES eax
    mov eax, g_ActiveProg
    mov g_D_PROG, eax
    
    mov eax, g_ActiveVerb
    mov g_D_VERB, eax
    
    mov eax, g_ActiveNoun
    mov g_D_NOUN, eax
    
    mov eax, g_ActiveR1
    mov g_D_R1, eax
    
    mov eax, g_ActiveR2
    mov g_D_R2, eax
    
    mov eax, g_ActiveR3
    mov g_D_R3, eax
    
    ret
SyncActiveToDisplay ENDP

END