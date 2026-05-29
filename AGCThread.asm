INCLUDE Irvine32.inc

option casemap:none

INCLUDE AGCThread.inc
INCLUDE WinAPIs.inc
INCLUDE Globals.inc

.data
    s_BlinkCycle    DWORD 0      ; 用於追蹤閃爍週期的計數器
    
    ; 燈泡測試時用來暫存原本狀態的變數
    s_SaveDskyState DWORD 0
    qwDueTime       QWORD 0

.data?
    hTimer          DWORD ?

.code
AGCThread PROC lpParam:DWORD

    INVOKE CreateWaitableTimer, NULL, FALSE, NULL
    mov hTimer, eax
    INVOKE SetWaitableTimer, hTimer, OFFSET qwDueTime, 50, NULL, NULL, FALSE

_AGCLoop:
    ; ----------------------------------------------------
    ; 1. 處理 V35E 燈泡測試 (Lamp Test)
    ; ----------------------------------------------------
    cmp g_LampTestTimer, 0
    je _ProcessProgTimer
    
    ; 如果計時器剛好被設為 5000，代表剛觸發，需備份 g_DskyState 狀態
    cmp g_LampTestTimer, TIMER_LAMP_TEST
    jne _LampTestActive
    mov eax, g_DskyState
    mov s_SaveDskyState, eax
    
    ; 點亮所有燈，全部數字設為 88888
    or g_DskyState, 1111111111111b XOR MASK D_COMP_ACTY
    mov g_D_PROG, 88
    mov g_D_VERB, 88
    mov g_D_NOUN, 88
    mov g_D_R1, 88888
    mov g_D_R2, 88888
    mov g_D_R3, 88888

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

    INVOKE SyncActiveToDisplay

    mov g_LampTestTimer, 0

_ProcessProgTimer:
    ; ----------------------------------------------------
    ; 2. 處理 PROG 01 -> PROG 02 的 5000ms 自動跳轉
    ; ----------------------------------------------------
    cmp g_Prog01Timer, 0
    je _ProcessBlinking
    sub g_Prog01Timer, 50
    jg _ProcessBlinking
    
    ; 倒數結束，呼叫 HandleTimerProg01 跳轉至 PROG 02
    INVOKE HandleTimerProg01

_ProcessBlinking:
    ; ----------------------------------------------------
    ; 3. 處理 COMP ACTY 動畫 (閃爍邏輯)
    ; ----------------------------------------------------
    add s_BlinkCycle, 50
        
    cmp g_ActiveProg, 2
    je _BlinkProg02
    
    cmp g_ActiveProg, 11
    je _BlinkProg11
    
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
    ; 執行緒睡眠 50 毫秒，避免佔用 100% CPU
    ; INVOKE Sleep, 50
    INVOKE WaitForSingleObject, hThread, INFINITE
    jmp _AGCLoop

    ret
AGCThread ENDP
END