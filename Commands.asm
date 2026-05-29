INCLUDE Irvine32.inc
option casemap:none
INCLUDE Globals.inc

.code

; =======================================================
; 1. HandleEnter: 處理使用者按下 E (Enter) 的邏輯
; =======================================================
HandleEnter PROC USES eax ebx
    cmp g_InputMode, INPUT_VERB
    je _HandleVerbSubmit
    cmp g_InputMode, INPUT_PROG
    je _HandleProgSubmit
    jmp _Done

_HandleVerbSubmit:
    mov eax, g_InputBuffer

    cmp eax, 35             ; V35E 燈泡測試
    jne _CheckV37
    mov g_LampTestTimer, TIMER_LAMP_TEST
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay  
    jmp _Done

_CheckV37:
    cmp eax, 37             ; V37E 準備切換 Program
    jne _CheckV82
    mov g_ActiveVerb, 37
    mov g_InputMode, INPUT_PROG
    INVOKE SyncActiveToDisplay  
    mov g_D_PROG, EMPTY         ; 特例：清空 PROG 畫面提示等待輸入
    jmp _Done

_CheckV82:
    cmp eax, 82             ; V82E 軌道參數
    jne _Error
    ; 直接檢查 ActiveProg 而非
    cmp g_ActiveProg, 11
    jne _Error
    
    mov g_ActiveVerb, 16
    mov g_ActiveNoun, 44
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay  
    jmp _Done

_HandleProgSubmit:
    mov eax, g_InputBuffer
    cmp eax, 1              ; PROG 01
    jne _Error

    mov g_ActiveProg, 1
    mov g_ActiveVerb, EMPTY
    mov g_ActiveNoun, EMPTY
    mov g_ActiveR1, EMPTY
    mov g_ActiveR2, EMPTY
    mov g_ActiveR3, EMPTY
    
    mov g_Prog01Timer, TIMER_PROG_01
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay  
    jmp _Done

_Error:
    or g_DskyState, MASK L_OPR_ERR
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay  
    jmp _Done

_Done:
    ret
HandleEnter ENDP


; =======================================================
; 2. HandlePro: 處理按下 PRO 鍵的狀態切換
; =======================================================
HandlePro PROC
    ; 只有在 PROG 11 且 V16N44 時，PRO 鍵才有作用
    cmp g_ActiveProg, 11
    jne _Done
    cmp g_ActiveVerb, 16
    jne _Done
    
    mov g_ActiveVerb, 6
    mov g_ActiveNoun, 62
    INVOKE SyncActiveToDisplay
_Done:
    ret
HandlePro ENDP


; =======================================================
; 3. HandleReturn: 處理按下 VK_RETURN 的狀態切換
; =======================================================
HandleReturn PROC
    ; 若目前是 PROG 02，跳轉至 PROG 11
    cmp g_ActiveProg, 2
    jne _Done
    
    mov g_ActiveProg, 11
    mov g_ActiveVerb, 6
    mov g_ActiveNoun, 62
    mov g_ActiveR1, 12345       ; (暫代資料)
    mov g_ActiveR2, 54321       ; (暫代資料)
    INVOKE SyncActiveToDisplay
_Done:
    ret
HandleReturn ENDP


; =======================================================
; 4. HandleTimerProg01: 處理 PROG 01 的 5 秒計時器結束
; =======================================================
HandleTimerProg01 PROC
    ; 確認目前仍在 PROG 01 才進行跳轉
    cmp g_ActiveProg, 1
    jne _Done
    
    mov g_ActiveProg, 2
    INVOKE SyncActiveToDisplay
_Done:
    ret
HandleTimerProg01 ENDP

END