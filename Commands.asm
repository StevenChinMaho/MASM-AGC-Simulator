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
    ; 【關鍵修復】V35E 是一個觸發動作，不會改變系統的 Active 狀態。
    ; 我們直接把畫面上的 VERB 恢復成系統真正的 ActiveVerb，消除 '35' 的殘影
    mov ebx, g_ActiveVerb
    mov g_D_VERB, ebx
    mov g_InputMode, INPUT_NONE
    jmp _Done

_CheckV37:
    ; === 處理 V37E (準備切換 Program) ===
    cmp eax, 37
    jne _CheckV82
    ; 這裡只更新真實狀態與畫面，然後把模式切換為等待 PROG
    mov g_ActiveVerb, 37
    mov g_InputMode, INPUT_PROG
    mov g_D_PROG, EMPTY         ; 清空 PROG 畫面提示輸入
    jmp _Done

_CheckV82:
    ; === 處理 V82E (Orbit Parameters) ===
    cmp eax, 82
    jne _Error
    ; 只有在 PROG 11 才能執行 V82E
    cmp g_SystemState, SYS_PROG_11
    jne _Error
    
    ; 真正改變系統狀態
    mov g_ActiveVerb, 16
    mov g_ActiveNoun, 44
    ; 同步到畫面上
    mov g_D_VERB, 16
    mov g_D_NOUN, 44
    mov g_InputMode, INPUT_NONE
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
    
    ; 同步到畫面顯示
    mov g_D_PROG, 1
    mov g_D_VERB, EMPTY
    mov g_D_NOUN, EMPTY
    mov g_D_R1, EMPTY
    mov g_D_R2, EMPTY
    mov g_D_R3, EMPTY
    
    mov g_Prog01Timer, TIMER_PROG_01
    mov g_InputMode, INPUT_NONE
    jmp _Done

_Error:
    ; 亮起 OPR ERR 燈號
    or g_DskyState, MASK L_OPR_ERR
    mov g_InputMode, INPUT_NONE
    
    ; 【友善設計】如果輸入錯誤，把畫面上打錯的數字抹除，恢復成系統真實的狀態
    mov eax, g_ActiveVerb
    mov g_D_VERB, eax
    mov eax, g_ActiveNoun
    mov g_D_NOUN, eax
    mov eax, g_ActiveProg
    mov g_D_PROG, eax

_Done:
    ret
ExecuteCommand ENDP

END