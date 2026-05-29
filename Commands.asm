INCLUDE Irvine32.inc
option casemap:none
INCLUDE Globals.inc

; =======================================================
; 定義指令對應表結構 (支援 Verb + Noun 組合)
; =======================================================
CommandEntry STRUCT
    Verb    DWORD ?     ; 指令 Verb
    Noun    DWORD ?     ; 指令 Noun (若不需 Noun 則為 EMPTY)
    Handler DWORD ?     ; 處理區塊
CommandEntry ENDS

.code

; =======================================================
; 1. HandleEnter: 處理使用者按下 E 的邏輯
; =======================================================
HandleEnter PROC USES eax ebx ecx edx esi
    ; 如果是輸入 PROG 號碼，走獨立邏輯
    cmp g_InputMode, INPUT_PROG
    je _HandleProgSubmit

    ; 只有在 VERB 或 NOUN 模式下按 E，才進行查表
    cmp g_InputMode, INPUT_VERB
    je _ProcessVerbNoun
    cmp g_InputMode, INPUT_NOUN
    je _ProcessVerbNoun
    jmp _Done

; -------------------------------------------------------
; 組合鍵表驅動搜尋器
; -------------------------------------------------------
_ProcessVerbNoun:
    mov eax, g_PendingVerb          ; EAX = 組合的 Verb
    mov ebx, g_PendingNoun          ; EBX = 組合的 Noun
    mov ecx, VerbTableLen           
    mov esi, OFFSET VerbTable       

_SearchLoop:
    cmp [esi].CommandEntry.Verb, eax    ; 比對 Verb
    jne _Next
    cmp [esi].CommandEntry.Noun, ebx    ; 比對 Noun
    jne _Next
    
    ; 全命中！
    mov edx, [esi].CommandEntry.Handler
    jmp edx                             

_Next:
    add esi, SIZEOF CommandEntry        
    loop _SearchLoop                    

    jmp _Error

; =======================================================
; 各個組合指令的處理邏輯
; =======================================================
_CmdV16N65::
    mov g_ActiveVerb, 16
    mov g_ActiveNoun, 65
    or g_DskyState, MASK L_KEY_REL
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay  
    jmp _Done

_CmdV35::
    and g_DskyState, NOT MASK L_KEY_REL
    mov g_LampTestTimer, TIMER_LAMP_TEST
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay  
    jmp _Done

_CmdV37::
    mov g_InputMode, INPUT_PROG
    INVOKE SyncActiveToDisplay  
    mov g_D_VERB, 37            
    mov g_D_PROG, EMPTY         
    jmp _Done

_CmdV82::
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
    cmp eax, 1              
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

_Error:
    or g_DskyState, MASK L_OPR_ERR
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay  
    jmp _Done

_Done:
    ret
HandleEnter ENDP

; =======================================================
; HandleKeyRel
; =======================================================
HandleKeyRel PROC
    and g_DskyState, NOT MASK L_KEY_REL

    cmp g_ActiveVerb, 16
    jne _CheckInput
    cmp g_ActiveNoun, 65
    jne _CheckInput

    mov g_ActiveVerb, 6
    mov g_ActiveNoun, 62
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay
    jmp _Done

_CheckInput:
    cmp g_InputMode, INPUT_NONE
    je _Done
    
    mov g_InputMode, INPUT_NONE
    INVOKE SyncActiveToDisplay
_Done:
    ret
HandleKeyRel ENDP

; =======================================================
; HandleClr
; =======================================================
HandleClr PROC
    cmp g_InputMode, INPUT_VERB
    je _ClrVerb
    cmp g_InputMode, INPUT_NOUN
    je _ClrNoun
    cmp g_InputMode, INPUT_PROG
    je _ClrProg
    jmp _Done

_ClrVerb:
    mov g_PendingVerb, 0
    mov g_InputBuffer, 0
    mov g_D_VERB, EMPTY
    jmp _Done
_ClrNoun:
    mov g_PendingNoun, 0
    mov g_InputBuffer, 0
    mov g_D_NOUN, EMPTY
    jmp _Done
_ClrProg:
    mov g_D_PROG, EMPTY
    mov g_InputBuffer, 0
    jmp _Done

_Done:
    ret
HandleClr ENDP

; =======================================================
; HandlePro
; =======================================================
HandlePro PROC
    cmp g_ActiveVerb, 16
    jne _Done
    
    cmp g_ActiveNoun, 44
    je _HandleV16N44
    
    cmp g_ActiveNoun, 65
    je _ReturnToMain
    
    jmp _Done

_HandleV16N44:
    cmp g_ActiveProg, 11
    jne _Done
    jmp _ReturnToMain

_ReturnToMain:
    mov g_ActiveVerb, 6
    mov g_ActiveNoun, 62
    mov g_FlashNoun, 0
    mov g_FlashVerb, 0
    and g_DskyState, NOT MASK L_KEY_REL
    INVOKE SyncActiveToDisplay
_Done:
    ret
HandlePro ENDP

; =======================================================
; HandleReturn & HandleTimerProg01
; =======================================================
HandleReturn PROC
    cmp g_ActiveProg, 2
    jne _Done
    mov g_ActiveProg, 11
    mov g_ActiveVerb, 6
    mov g_ActiveNoun, 62
    INVOKE SyncActiveToDisplay
_Done:
    ret
HandleReturn ENDP

HandleTimerProg01 PROC
    cmp g_ActiveProg, 1
    jne _Done
    mov g_ActiveProg, 2
    INVOKE SyncActiveToDisplay
_Done:
    ret
HandleTimerProg01 ENDP

.data
    ; === 組合指令字典 (Verb, Noun, Handler) ===
    VerbTable CommandEntry <16, 65, OFFSET _CmdV16N65>
              CommandEntry <35, EMPTY, OFFSET _CmdV35>
              CommandEntry <37, EMPTY, OFFSET _CmdV37>
              CommandEntry <82, EMPTY, OFFSET _CmdV82>
    VerbTableLen DWORD 4

END