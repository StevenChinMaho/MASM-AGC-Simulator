INCLUDE Irvine32.inc

option casemap:none

INCLUDE DSKY.inc
INCLUDE WinAPIs.inc
INCLUDE AGCThread.inc
INCLUDE Globals.inc

.data
    INCLUDE DSKY_UI.inc

    DescriptionString BYTE "AGC DSKY Simulator - Table Driven & Threading", 0
    
.data?
    hThread     DWORD ?

.code

pikachu:
    ; =========== 畫面初始化 ============
    INVOKE SetConsoleOutputCP, 65001            ; 設定輸出使用 UTF-8 編碼

    mov edx, OFFSET dskyUI
    call WriteString

    INVOKE RenderDSKY

    mov dx, ((2 SHL 8) OR 60)
    call Gotoxy
    mov edx, OFFSET DescriptionString
    call WriteString
    ; =================================

    call ReadChar       ; 等待使用者按下任意鍵後開始模擬 

    ; ========== 建立計時器與事件，並啟動模擬執行緒 ==========
    ; INVOKE CreateWaitableTimer, NULL, FALSE, NULL
    ; mov hTimer, eax
    ; mov WaitEvents[TYPE WaitEvents * 0], eax
    ; INVOKE SetWaitableTimer, hTimer, OFFSET qwDueTime, 2000, NULL, NULL, FALSE

    ; INVOKE CreateEvent, NULL, TRUE, FALSE, NULL
    ; mov hExitEvent, eax
    ; mov WaitEvents[TYPE WaitEvents * 1], eax

    INVOKE CreateThread, NULL, 0, OFFSET AGCThread, NULL, 0, NULL
    mov hThread, eax
    ; =========================================================

    mov g_DskyState, 1 SHL L_PROG

    _MainLoop:
        INVOKE RenderDSKY
        call ReadKey
        jz ContinueLoop           ; 如果沒有按鍵輸入，繼續等待

        cmp al, VK_ESCAPE
        je ExitLoop

        INVOKE ProcessKey, al
        
ContinueLoop:
        INVOKE Sleep, 50
        jmp _MainLoop
    
ExitLoop:

    ; ========== 重置 DSKY 顯示的數值與狀態燈 ==========
    mov g_D_PROG, 88
    mov g_D_VERB, 88
    mov g_D_NOUN, 88
    mov g_D_R1, 88888
    mov g_D_R2, 88888
    mov g_D_R3, 88888

    or g_DskyState, 1111111111111b

    INVOKE RenderDSKY

    ; ========== 通知執行緒結束並等待其結束 ==========
    ; INVOKE SetEvent, hExitEvent
    ; INVOKE WaitForSingleObject, hThread, INFINITE
    ; INVOKE CloseHandle, hTimer
    ; INVOKE CloseHandle, hExitEvent
    ; INVOKE CloseHandle, hThread

    INVOKE ExitProcess, 0

END pikachu
