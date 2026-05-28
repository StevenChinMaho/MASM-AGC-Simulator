INCLUDE Irvine32.inc
option casemap:none
INCLUDE Globals.inc

.code

; =======================================================
; ExecuteCommand: 分析目前的 Verb, Noun, Prog 來決定動作
; =======================================================
ExecuteCommand PROC USES eax ebx
    
    ; === 處理 V35E (燈泡測試) ===
    cmp g_D_VERB, 35
    jne _CheckV37
    ; 設定 Lamp Test 計時器為 5000 毫秒 (背景 Thread 會接手)
    mov g_LampTestTimer, 5000
    mov g_InputMode, INPUT_NONE
    jmp _Done

_CheckV37:
    ; === 處理 V37E 01E (切換 Program) ===
    cmp g_D_VERB, 37
    jne _CheckV82
    
    ; 如果使用者只是剛打了 V 37 E，我們要把系統設為等待 Prog 輸入
    cmp g_InputMode, INPUT_VERB
    jne _CheckV37Prog
    mov g_InputMode, INPUT_PROG
    mov g_D_PROG, EMPTY
    jmp _Done

_CheckV37Prog:
    ; 如果使用者是打了 V 37 E，然後又打了 0 1 E
    cmp g_InputMode, INPUT_PROG
    jne _Done
    cmp g_InputBuffer, 1
    jne _Error

    ; 成功進入 PROG 01
    mov g_SystemState, SYS_PROG_01
    mov g_D_PROG, 1
    mov g_D_VERB, EMPTY
    mov g_D_NOUN, EMPTY
    mov g_D_R1, EMPTY
    mov g_D_R2, EMPTY
    mov g_D_R3, EMPTY
    ; 啟動 PROG 01 轉 PROG 02 的 5 秒倒數
    mov g_Prog01Timer, 5000
    mov g_InputMode, INPUT_NONE
    jmp _Done

_CheckV82:
    ; === 處理 V82E (Orbit Parameters) ===
    cmp g_D_VERB, 82
    jne _Error
    ; 只有在 PROG 11 才能執行 V82E
    cmp g_SystemState, SYS_PROG_11
    jne _Error
    
    mov g_D_VERB, 16
    mov g_D_NOUN, 44
    mov g_InputMode, INPUT_NONE
    jmp _Done

_Error:
    ; 亮起 OPR ERR 燈號
    or g_DskyState, MASK L_OPR_ERR
    mov g_InputMode, INPUT_NONE

_Done:
    ret
ExecuteCommand ENDP

END