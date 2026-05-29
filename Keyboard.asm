INCLUDE Irvine32.inc
option casemap:none
INCLUDE Globals.inc

.code

; =======================================================
; ProcessKey: 處理單一按鍵輸入
; 使用 Jump Table 取代冗長的 cmp/je
; =======================================================
ProcessKey PROC USES eax ebx ecx edx, key:BYTE
    mov al, key

    ; 統一轉大寫
    cmp al, 'a'
    jb _CheckDigit
    cmp al, 'z'
    ja _CheckDigit
    sub al, 32

_CheckDigit:
    ; 若為數字 (0-9)
    cmp al, '0'
    jb _CheckSpecialKeys
    cmp al, '9'
    ja _CheckSpecialKeys
    
    ; 數字累加邏輯: Buffer = Buffer * 10 + (key - '0')
    sub al, '0'
    movzx ebx, al
    mov eax, g_InputBuffer
    mov ecx, 10
    mul ecx
    add eax, ebx
    mov g_InputBuffer, eax

    ; 即時更新顯示 (所見即所得)
    cmp g_InputMode, INPUT_VERB
    jne _CheckNoun
    mov g_D_VERB, eax
    jmp _Done
_CheckNoun:
    cmp g_InputMode, INPUT_NOUN
    jne _CheckProg
    mov g_D_NOUN, eax
    jmp _Done
_CheckProg:
    cmp g_InputMode, INPUT_PROG
    jne _Done
    mov g_D_PROG, eax
    jmp _Done

_CheckSpecialKeys:
    cmp al, 'V'
    je _HandleVerb
    cmp al, 'N'
    je _HandleNoun
    cmp al, 'E'
    je _HandleEnter
    cmp al, 'P'
    je _HandlePro
    cmp al, 'R'
    je _HandleReset
    cmp al, VK_RETURN   
    je _HandleReturn
    jmp _Done

_HandleVerb:
    mov g_InputMode, INPUT_VERB
    mov g_InputBuffer, 0
    mov g_D_VERB, EMPTY         ; 暫時清空畫面，準備接收數字
    jmp _Done

_HandleNoun:
    mov g_InputMode, INPUT_NOUN
    mov g_InputBuffer, 0
    mov g_D_NOUN, EMPTY         ; 暫時清空畫面，準備接收數字
    jmp _Done

_HandleEnter:
    INVOKE HandleEnter          ; 【解耦】外包給狀態控制器
    mov g_InputBuffer, 0
    jmp _Done

_HandleReset:
    and g_DskyState, NOT MASK L_OPR_ERR
    mov g_InputMode, INPUT_NONE
    mov g_InputBuffer, 0
    INVOKE SyncActiveToDisplay  ; 直接同步，消除畫面上打錯的數字
    jmp _Done

_HandlePro:
    INVOKE HandlePro            ; 【解耦】外包給狀態控制器
    jmp _Done

_HandleReturn:
    INVOKE HandleReturn         ; 【解耦】外包給狀態控制器
    jmp _Done

_Done:
    ret
ProcessKey ENDP

END