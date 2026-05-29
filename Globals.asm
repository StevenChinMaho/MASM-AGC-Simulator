INCLUDE Irvine32.inc
option casemap:none
INCLUDE Globals.inc

.data
    ; --- 系統與輸入狀態 ---
    g_InputMode     DWORD INPUT_NONE
    g_InputBuffer   DWORD 0
    
    ; --- 計時器 ---
    g_LampTestTimer DWORD 0
    g_Prog01Timer   DWORD 0

    ; 系統真實的狀態 (Model 預設為 EMPTY)
    g_ActiveProg DWORD EMPTY
    g_ActiveVerb DWORD EMPTY
    g_ActiveNoun DWORD EMPTY
    g_ActiveR1   DWORD 0
    g_ActiveR2   DWORD 0
    g_ActiveR3   DWORD 0

    ; --- DSKY 顯示變數 (預設初始狀態) ---
    g_D_PROG DWORD EMPTY
    g_D_VERB DWORD EMPTY
    g_D_NOUN DWORD EMPTY
    g_D_R1   DWORD 0
    g_D_R2   DWORD 0
    g_D_R3   DWORD 0

END