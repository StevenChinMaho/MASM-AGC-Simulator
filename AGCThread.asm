INCLUDE Irvine32.inc

option casemap:none

INCLUDE AGCThread.inc
INCLUDE WinAPIs.inc
INCLUDE Globals.inc

.data
    s_BlinkCycle DWORD 0      ; 用於追蹤閃爍週期的計數器
    
    ; 燈泡測試時用來暫存原本狀態的變數
    s_SaveDskyState DWORD 0
    s_SaveR1 DWORD 0
    s_SaveR2 DWORD 0
    s_SaveR3 DWORD 0
.code
AGCThread PROC lpParam:DWORD
_AGCLoop:
    ; ----------------------------------------------------
    ; 1. 處理 V35E 燈泡測試 (Lamp Test)
    ; ----------------------------------------------------
    cmp g_LampTestTimer, 0
    je _ProcessProgTimer
    
    ; 如果計時器剛好被設為 5000，代表剛觸發，需備份原本狀態
    cmp g_LampTestTimer, 5000
    jne _LampTestActive
    mov eax, g_DskyState
    mov s_SaveDskyState, eax
    mov eax, g_D_R1
    mov s_SaveR1, eax
    mov eax, g_D_R2
    mov s_SaveR2, eax
    mov eax, g_D_R3
    mov s_SaveR3, eax
    
    ; 點亮所有燈，全部數字設為 88888
    or g_DskyState, 1111111111111b
    mov g_D_R1, 88888
    mov g_D_R2, 88888
    mov g_D_R3, 88888

_LampTestActive:
    sub g_LampTestTimer, 50
    jg _ProcessProgTimer
    
    ; 計時器歸零，恢復原本狀態
    mov eax, s_SaveDskyState
    mov g_DskyState, eax
    mov eax, s_SaveR1
    mov g_D_R1, eax
    mov eax, s_SaveR2
    mov g_D_R2, eax
    mov eax, s_SaveR3
    mov g_D_R3, eax
    mov g_LampTestTimer, 0

_ProcessProgTimer:
    ; ----------------------------------------------------
    ; 2. 處理 PROG 01 -> PROG 02 的 5000ms 自動跳轉
    ; ----------------------------------------------------
    cmp g_Prog01Timer, 0
    je _ProcessBlinking
    sub g_Prog01Timer, 50
    jg _ProcessBlinking
    
    ; 倒數結束，且目前仍在 PROG 01，則跳轉至 PROG 02
    cmp g_SystemState, SYS_PROG_01
    jne _ProcessBlinking
    mov g_SystemState, SYS_PROG_02
    mov g_D_PROG, 2

_ProcessBlinking:
    ; ----------------------------------------------------
    ; 3. 處理 COMP ACTY 動畫 (閃爍邏輯)
    ; ----------------------------------------------------
    add s_BlinkCycle, 50

    cmp g_SystemState, SYS_PROG_02
    je _BlinkProg02
    
    cmp g_SystemState, SYS_PROG_11
    je _BlinkProg11
    
    ; 其他狀態關閉 COMP ACTY 燈
    and g_DskyState, NOT MASK D_COMP_ACTY
    jmp _ThreadSleep

_BlinkProg02:
    ; PROG 02: 400ms off, 100ms on (總週期 500ms)
    cmp s_BlinkCycle, 500
    jl _Prog02CheckOn
    mov s_BlinkCycle, 0    ; 重置週期
_Prog02CheckOn:
    cmp s_BlinkCycle, 400
    jl _TurnOffComp
    jmp _TurnOnComp

_BlinkProg11:
    ; PROG 11: 1500ms off, 500ms on (總週期 2000ms)
    cmp s_BlinkCycle, 2000
    jl _Prog11CheckOn
    mov s_BlinkCycle, 0    ; 重置週期
_Prog11CheckOn:
    cmp s_BlinkCycle, 1500
    jl _TurnOffComp
    jmp _TurnOnComp

_TurnOnComp:
    or g_DskyState, MASK D_COMP_ACTY
    jmp _ThreadSleep

_TurnOffComp:
    and g_DskyState, NOT MASK D_COMP_ACTY

_ThreadSleep:
    ; 執行緒睡眠 50 毫秒，避免佔用 100% CPU
    INVOKE Sleep, 50
    jmp _AGCLoop

    ret
AGCThread ENDP
END