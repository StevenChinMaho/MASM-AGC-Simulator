INCLUDE Irvine32.inc
option casemap:none
INCLUDE Globals.inc

.code

; =======================================================
; ExecuteCommand: 當使用者按下 E (Enter) 時觸發
; 分析 InputMode 與 InputBuffer 來決定動作
; =======================================================
ExecuteCommand PROC USES eax ebx
    
    ; 1. 判斷目前按下 Enter 時，正在輸入哪一種模式？
    cmp g_InputMode, INPUT_VERB
    je _HandleVerbSubmit
    cmp g_InputMode, INPUT_PROG
    je _HandleProgSubmit
    jmp _Done     ; 若不是預期的模式 (如 INPUT_NONE)，直接忽略

_HandleVerbSubmit:
    mov eax, g_InputBuffer      ; 取出使用者剛輸入的數字

    ; === 處理 V35E (燈泡測試) ===
    cmp eax, 35
    jne _CheckV37
    mov g_LampTestTimer, TIMER_LAMP_TEST
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay   ; 【一行搞定】消除輸入時的 35 殘影，恢復真實狀態
    jmp _Done

_CheckV37:
    ; === 處理 V37E (準備切換 Program) ===
    cmp eax, 37
    jne _CheckV82
    mov g_ActiveVerb, 37
    mov g_InputMode, INPUT_PROG
    INVOKE SyncActiveToDisplay   ; 【一行搞定】同步真實狀態
    mov g_D_PROG, EMPTY          ; 因為要輸入 PROG，所以特例把顯示清空提示使用者
    jmp _Done

_CheckV82:
    ; === 處理 V82E (Orbit Parameters) ===
    cmp eax, 82
    jne _Error
    ; 只有在 PROG 11 才能執行 V82E
    cmp g_SystemState, SYS_PROG_11
    jne _Error
    
    mov g_ActiveVerb, 16
    mov g_ActiveNoun, 44
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay   ; 【一行搞定】同步真實狀態
    jmp _Done

_HandleProgSubmit:
    mov eax, g_InputBuffer

    ; 目前只有 V37E 之後會進入這個區塊，所以預期輸入必須是 01
    cmp eax, 1
    jne _Error

    ; === 成功進入 PROG 01 ===
    mov g_SystemState, SYS_PROG_01
    
    ; 更新真實狀態 (PROG 變成 1，清除 Verb 與 Noun)
    mov g_ActiveProg, 1
    mov g_ActiveVerb, EMPTY
    mov g_ActiveNoun, EMPTY
    mov g_ActiveR1, EMPTY
    mov g_ActiveR2, EMPTY
    mov g_ActiveR3, EMPTY
    
    mov g_Prog01Timer, TIMER_PROG_01
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay   ; 【一行搞定】同步真實狀態
    jmp _Done

_Error:
    ; 亮起 OPR ERR 燈號
    or g_DskyState, MASK L_OPR_ERR
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay   ; 【一行搞定】輸入錯誤，清除畫面的錯誤數字，直接恢復原本狀態

_Done:
    ret
ExecuteCommand ENDP

END