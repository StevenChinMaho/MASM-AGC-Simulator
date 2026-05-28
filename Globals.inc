IFNDEF GLOBALS_INC
GLOBALS_INC EQU 1

INCLUDE DSKY.inc

; --- 系統狀態常數 ---
SYS_INIT    EQU 0
SYS_PROG_01 EQU 1
SYS_PROG_02 EQU 2
SYS_PROG_11 EQU 11

; --- 輸入模式常數 ---
INPUT_NONE  EQU 0
INPUT_VERB  EQU 1
INPUT_NOUN  EQU 2
INPUT_PROG  EQU 3

; --- 全域變數宣告 ---
EXTERNDEF g_SystemState:DWORD     ; 紀錄目前是 INIT, PROG 01, 02, 11
EXTERNDEF g_InputMode:DWORD       ; 目前正在輸入什麼 (Verb, Noun, Prog)
EXTERNDEF g_InputBuffer:DWORD     ; 使用者輸入的數字暫存

EXTERNDEF g_LampTestTimer:DWORD   ; V35E 燈泡測試計時器
EXTERNDEF g_Prog01Timer:DWORD     ; PROG 01 轉 PROG 02 的 5 秒計時器

; 跨檔案的副程式宣告
ProcessKey PROTO, key:BYTE
ExecuteCommand PROTO

ENDIF