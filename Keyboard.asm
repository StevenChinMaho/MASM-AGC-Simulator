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
    ; === 查表法 (Jump Table) 處理特殊指令鍵 ===
    ; 為了簡化，這裡以字母 ASCII 進行基本分支
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
    cmp al, VK_RETURN   ; 處理圖表中的 VK_RETURN
    je _HandleReturn
    jmp _Done

_HandleVerb:
    mov g_InputMode, INPUT_VERB
    mov g_InputBuffer, 0
    mov g_D_VERB, EMPTY
    jmp _Done

_HandleNoun:
    mov g_InputMode, INPUT_NOUN
    mov g_InputBuffer, 0
    mov g_D_NOUN, EMPTY
    jmp _Done

_HandleEnter:
    ; 當按下 Enter 時，交給 Commands.asm 解析指令
    INVOKE ExecuteCommand
    mov g_InputBuffer, 0
    jmp _Done

_HandleReset:
    ; 處理 OPR ERR 重置
    and g_DskyState, NOT MASK L_OPR_ERR
    mov g_InputMode, INPUT_NONE
    mov g_InputBuffer, 0
    jmp _Done

_HandlePro:
    ; PRO 鍵：若是 PROG 11 且目前在 V16N44，切回 V06N62
    cmp g_SystemState, SYS_PROG_11
    jne _Done
    cmp g_D_VERB, 16
    jne _Done
    mov g_D_VERB, 6
    mov g_D_NOUN, 62
    jmp _Done

_HandleReturn:
    ; VK_RETURN 鍵：若目前是 PROG 02，跳轉至 PROG 11
    cmp g_SystemState, SYS_PROG_02
    jne _Done
    mov g_SystemState, SYS_PROG_11
    mov g_D_PROG, 11
    mov g_D_VERB, 6
    mov g_D_NOUN, 62
    ; PROG 11 初始 R1/R2/R3 (It depends，此處給假資料)
    mov g_D_R1, 12345
    mov g_D_R2, 54321
    jmp _Done

_Done:
    ret
ProcessKey ENDP

END