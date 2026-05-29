INCLUDE Irvine32.inc

option casemap:none

INCLUDE AGCThread.inc
INCLUDE WinAPIs.inc
INCLUDE Globals.inc

.data
    s_BlinkCycle    DWORD 0      ; 用於追蹤閃爍週期的計數器
    
    ; 燈泡測試時用來暫存原本狀態的變數
    s_SaveDskyState DWORD 0
    s_SaveFlashVerb DWORD 0
    s_SaveFlashNoun DWORD 0
    qwDueTime       QWORD 0

.data?
    hTimer          DWORD ?

.code
AGCThread PROC lpParam:DWORD

    INVOKE CreateWaitableTimer, NULL, FALSE, NULL
    mov hTimer, eax
    INVOKE SetWaitableTimer, hTimer, OFFSET qwDueTime, 50, NULL, NULL, FALSE

_AGCLoop:
    ; ====================================================
    ; 0. 更新時鐘與全域閃爍節拍器
    ; ====================================================
    add g_UptimeMs, 50            ; 每次迴圈穩定增加 50ms
    
    ; 只有在 PROG 11 之後才計算 MET
    cmp g_ActiveProg, 11
    jl _CalcBlink
    add g_METMs, 50

_CalcBlink:
    ; ====================================================
    ; 產生全域同步閃爍訊號 (200ms 暗, 600ms 亮, 總週期 800ms)
    ; ====================================================
    mov eax, g_UptimeMs
    mov ebx, 800            ; 總週期 800ms
    xor edx, edx
    div ebx                 ; EAX = 商數, EDX = 餘數 (UptimeMs % 800)

    ; 判斷目前時間落在哪個週期區間
    cmp edx, 200
    jl _SetDark             ; 如果餘數 < 200ms -> 切換為暗
    
    ; 否則 (餘數 >= 200ms) -> 切換為亮
    mov g_MasterBlink, 1    
    jmp _BlinkDone
    
_SetDark:
    mov g_MasterBlink, 0
    
_BlinkDone:

    ; ----------------------------------------------------
    ; 1. 處理 V35E 燈泡測試 (Lamp Test)
    ; ----------------------------------------------------
    cmp g_LampTestTimer, 0
    je _ProcessProgTimer
    
    ; 如果計時器剛好被設為 5000，代表剛觸發，需備份 g_DskyState 與閃爍狀態
    cmp g_LampTestTimer, TIMER_LAMP_TEST
    jne _LampTestActive
    mov eax, g_DskyState
    mov s_SaveDskyState, eax
    mov eax, g_FlashVerb
    mov s_SaveFlashVerb, eax
    mov eax, g_FlashNoun
    mov s_SaveFlashNoun, eax
    
    ; 點亮部分所需的燈，全部數字設為 88888
    or g_DskyState, 1111110101001b XOR MASK D_COMP_ACTY
    mov g_D_PROG, 88
    mov g_D_VERB, 88
    mov g_D_NOUN, 88
    mov g_D_R1, 88888
    mov g_D_R2, 88888
    mov g_D_R3, 88888
    ; VERB 和 NOUN 設為閃爍
    mov g_FlashVerb, 1
    mov g_FlashNoun, 1

_LampTestActive:
    sub g_LampTestTimer, 50
    jg _ProcessProgTimer
    
    ; 計時器歸零，恢復原本狀態
    mov eax, s_SaveDskyState
    mov ebx, g_DskyState
    and ebx, MASK D_COMP_ACTY       ; 取出當前真實的 COMP ACTY 狀態
    and eax, NOT MASK D_COMP_ACTY   ; 抹除舊存檔裡的 COMP ACTY 狀態
    or eax, ebx                     ; 完美結合兩者
    mov g_DskyState, eax
    mov eax, s_SaveFlashVerb        ; 回復 VERB 與 NOUN 閃爍狀態
    mov g_FlashVerb, eax           
    mov eax, s_SaveFlashNoun   
    mov g_FlashNoun, eax

    INVOKE SyncActiveToDisplay

    mov g_LampTestTimer, 0

_ProcessProgTimer:
    ; ----------------------------------------------------
    ; 2. 處理 PROG 01 -> PROG 02 的自動跳轉與腳本燈效
    ; ----------------------------------------------------
    cmp g_Prog01Timer, 0
    je _ProcessBlinking
    sub g_Prog01Timer, 50
    jg _CheckProg01Sequence
    
    ; 倒數結束，呼叫 HandleTimerProg01 跳轉至 PROG 02
    INVOKE HandleTimerProg01
    jmp _ProcessBlinking

_CheckProg01Sequence:
    ; --- 腳本式燈效判定 ---
    cmp g_Prog01Timer, 4000     ; (1) 過了 1 秒鐘
    jne _Seq_1
    or g_DskyState, MASK D_COMP_ACTY
    jmp _ProcessBlinking
    
_Seq_1:
    cmp g_Prog01Timer, 3800     ; (2) COMP ACTY 亮了 200ms 後
    jne _Seq_2
    and g_DskyState, NOT MASK D_COMP_ACTY   ; 關閉 COMP ACTY
    or g_DskyState, MASK L_NO_ATT           ; 點亮 NO ATT
    jmp _ProcessBlinking
    
_Seq_2:
    cmp g_Prog01Timer, 1000      ; (3) NO ATT 亮了 2.8 秒鐘 (3800 - 2800 = 1000)
    jne _ProcessBlinking
    and g_DskyState, NOT MASK L_NO_ATT      ; 關閉 NO ATT，剩下的 900ms 靜靜等待
    jmp _ProcessBlinking

_ProcessBlinking:
    ; ----------------------------------------------------
    ; 3. 處理 COMP ACTY 動畫 (閃爍邏輯)
    ; ----------------------------------------------------
    add s_BlinkCycle, 50
        
    cmp g_ActiveProg, 2
    je _BlinkProg02
    
    cmp g_ActiveProg, 11
    je _BlinkProg11

    cmp g_ActiveProg, 1
    je _ThreadSleep
    
    ; 其他狀態關閉 COMP ACTY 燈
    and g_DskyState, NOT MASK D_COMP_ACTY
    jmp _ThreadSleep

_BlinkProg02:
    ; PROG 02: 400ms off, 100ms on (總週期 500ms)
    cmp s_BlinkCycle, BLINK_P02_ON
    jl _Prog02CheckOn
    mov s_BlinkCycle, 0    ; 重置週期
_Prog02CheckOn:
    cmp s_BlinkCycle, BLINK_P02_OFF
    jl _TurnOffComp
    jmp _TurnOnComp

_BlinkProg11:
    ; PROG 11: 1500ms off, 500ms on (總週期 2000ms)
    cmp s_BlinkCycle, BLINK_P11_ON
    jl _Prog11CheckOn
    mov s_BlinkCycle, 0    ; 重置週期
_Prog11CheckOn:
    cmp s_BlinkCycle, BLINK_P11_OFF
    jl _TurnOffComp
    jmp _TurnOnComp

_TurnOnComp:
    or g_DskyState, MASK D_COMP_ACTY
    jmp _ThreadSleep

_TurnOffComp:
    and g_DskyState, NOT MASK D_COMP_ACTY

_ThreadSleep:
    ; 執行緒等待下一個時鐘週期 (每50ms)
    INVOKE WaitForSingleObject, hTimer, INFINITE
    jmp _AGCLoop

    ret
AGCThread ENDP
END