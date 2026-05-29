INCLUDE Irvine32.inc
option casemap:none
INCLUDE Globals.inc

; =======================================================
; 定義指令對應表結構 (Table-Driven 的核心)
; =======================================================
CommandEntry STRUCT
    Code    DWORD ?     ; 使用者輸入的數字 (例如 35, 37, 82)
    Handler DWORD ?     ; 負責處理該指令的區塊位址 (Label Pointer)
CommandEntry ENDS

.code

; =======================================================
; 1. HandleEnter: 處理使用者按下 E (Enter) 的邏輯
; =======================================================
HandleEnter PROC USES eax ebx ecx edx esi
    cmp g_InputMode, INPUT_VERB
    je _HandleVerbSubmit
    cmp g_InputMode, INPUT_PROG
    je _HandleProgSubmit
    jmp _Done

; -------------------------------------------------------
; 表驅動的 Verb 搜尋器 (Table-Driven Dispatcher)
; -------------------------------------------------------
_HandleVerbSubmit:
    mov eax, g_InputBuffer          ; EAX = 使用者打的指令數字
    mov ecx, VerbTableLen           ; ECX = 迴圈次數 (表的大小)
    mov esi, OFFSET VerbTable       ; ESI = 指向表的開頭

_SearchLoop:
    cmp [esi].CommandEntry.Code, eax    ; 檢查字典的 Code 有沒有等於輸入的 EAX
    je _FoundCommand                    ; 找到了就跳轉
    add esi, SIZEOF CommandEntry        ; 沒找到，把指標往下推到下一個 Struct
    loop _SearchLoop                    ; 繼續找

    ; 如果整個迴圈跑完都沒找到，代表打錯指令
    jmp _Error

_FoundCommand:
    ; 找到對應的指令了！取出它專屬的區塊位址並直接跳轉
    mov edx, [esi].CommandEntry.Handler
    jmp edx                             ; 跳轉到對應的指令邏輯

; =======================================================
; 以下是各個 Verb 的專屬處理區塊 (Action Handlers)
; =======================================================
_CmdV35::
    and g_DskyState, NOT MASK L_KEY_REL
    mov g_LampTestTimer, TIMER_LAMP_TEST
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay  
    jmp _Done

_CmdV37::
    mov g_InputMode, INPUT_PROG
    INVOKE SyncActiveToDisplay  
    mov g_D_VERB, 37            ; 特例：更新螢幕後刻意保留 VERB 37  
    mov g_D_PROG, EMPTY         ; 清空 PROG 畫面提示等待輸入
    jmp _Done

_CmdV82::
    ; 直接檢查 ActiveProg
    cmp g_ActiveProg, 11
    jne _Error
    
    and g_DskyState, NOT MASK L_KEY_REL
    mov g_ActiveVerb, 16
    mov g_ActiveNoun, 44
    mov g_FlashNoun, 1
    mov g_FlashVerb, 1
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay  
    jmp _Done

; -------------------------------------------------------
; 處理 PROG 的輸入
; -------------------------------------------------------
_HandleProgSubmit:
    mov eax, g_InputBuffer
    cmp eax, 1              ; PROG 01
    jne _Error

    and g_DskyState, NOT MASK L_KEY_REL
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

; -------------------------------------------------------
; 錯誤處理與結束
; -------------------------------------------------------
_Error:
    or g_DskyState, MASK L_OPR_ERR
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay  
    jmp _Done

_Done:
    ret
HandleEnter ENDP

; =======================================================
; HandleKeyRel: 處理按下 KEY REL (K) 鍵
; 放棄手動輸入控制權，關閉提示燈，並將畫面強制恢復為背景狀態
; =======================================================
HandleKeyRel PROC
    ; 1. 無論如何，先關閉 KEY REL 的燈號與閃爍狀態
    and g_DskyState, NOT MASK L_KEY_REL

    ; 2. 檢查是否正在輸入中，如果不是，就什麼都不做
    cmp g_InputMode, INPUT_NONE
    je _Done
    
    ; 3. 取消正在進行的輸入，並將畫面洗回系統真實狀態 (Model)
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay
_Done:
    ret
HandleKeyRel ENDP

; =======================================================
; HandleClr: 處理按下 CLR (C) 鍵
; 只清除畫面上「目前正在編輯的欄位」，讓使用者可以重新打數字
; =======================================================
HandleClr PROC
    ; 根據目前的輸入模式，清空對應的顯示欄位 (View)
    cmp g_InputMode, INPUT_VERB
    je _ClrVerb
    cmp g_InputMode, INPUT_NOUN
    je _ClrNoun
    cmp g_InputMode, INPUT_PROG
    je _ClrProg
    jmp _Done

_ClrVerb:
    mov g_D_VERB, EMPTY
    jmp _Done
_ClrNoun:
    mov g_D_NOUN, EMPTY
    jmp _Done
_ClrProg:
    mov g_D_PROG, EMPTY
    jmp _Done

_Done:
    ret
HandleClr ENDP

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
    mov g_FlashNoun, 0
    mov g_FlashVerb, 0
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

.data
    ; === Verb 指令字典 ===
    ; 未來要新增任何 Verb，只要在這個陣列加一行就好！
    VerbTable CommandEntry <35, OFFSET _CmdV35>
              CommandEntry <37, OFFSET _CmdV37>
              CommandEntry <82, OFFSET _CmdV82>
    VerbTableLen DWORD 3   ; 字典裡的指令數量

END