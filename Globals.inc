IFNDEF GLOBALS_INC
GLOBALS_INC EQU 1

INCLUDE DSKY.inc

; --- 輸入模式常數 ---
INPUT_NONE  EQU 0
INPUT_VERB  EQU 1
INPUT_NOUN  EQU 2
INPUT_PROG  EQU 3

; --- 時間與動畫常數 (毫秒) ---
TIMER_LAMP_TEST EQU 5000
TIMER_PROG_01   EQU 5000
BLINK_P02_OFF   EQU 400
BLINK_P02_ON    EQU 500   ; 400 + 100
BLINK_P11_OFF   EQU 1500
BLINK_P11_ON    EQU 2000  ; 1500 + 500

; --- 全域變數宣告 (統一由此管理) ---
EXTERNDEF g_InputMode:DWORD       
EXTERNDEF g_InputBuffer:DWORD     

EXTERNDEF g_LampTestTimer:DWORD   
EXTERNDEF g_Prog01Timer:DWORD     

; 系統真實的狀態 (Model)
EXTERNDEF g_ActiveProg:DWORD
EXTERNDEF g_ActiveVerb:DWORD
EXTERNDEF g_ActiveNoun:DWORD
EXTERNDEF g_ActiveR1:DWORD
EXTERNDEF g_ActiveR2:DWORD
EXTERNDEF g_ActiveR3:DWORD

; DSKY 指示燈狀態
DskyStateRecord RECORD \
    RSVD:19=0,
    L_UPLINK_ACTY:1=0,
    L_NO_ATT:1=0,
    L_STBY:1=0,
    L_KEY_REL:1=0,
    L_OPR_ERR:1=0,
    L_TEMP:1=0,
    L_GIMBAL_LOCK:1=0,
    L_PROG:1=0,
    L_RESTART:1=0,
    L_TRACKER:1=0,
    L_ALT:1=0,
    L_VEL:1=0,
    D_COMP_ACTY:1=0
    
EXTERNDEF g_DskyState:DskyStateRecord

; DSKY 顯示變數 (View)
EXTERNDEF g_D_PROG:DWORD
EXTERNDEF g_D_VERB:DWORD
EXTERNDEF g_D_NOUN:DWORD
EXTERNDEF g_D_R1:DWORD
EXTERNDEF g_D_R2:DWORD
EXTERNDEF g_D_R3:DWORD

; --- 時間與閃爍控制 ---
EXTERNDEF g_UptimeMs:DWORD        ; 開機以來的總毫秒數
EXTERNDEF g_METMs:DWORD           ; 任務經過時間 (PROG 11 開始)
EXTERNDEF g_MasterBlink:DWORD     ; 0 或 1 (每 500ms 切換)

EXTERNDEF g_DskyFlashState:DskyStateRecord  ; 閃爍遮罩 (對應 g_DskyState 的位元，1代表該燈要閃爍)

; 控制數字區塊閃爍的開關 (1=閃爍, 0=常亮)
EXTERNDEF g_FlashVerb:DWORD
EXTERNDEF g_FlashNoun:DWORD

; 跨檔案的副程式宣告
ProcessKey PROTO, key:BYTE
ExecuteCommand PROTO
SyncActiveToDisplay PROTO

; 統一狀態轉換控制器 API
HandleEnter PROTO
HandlePro PROTO
HandleReturn PROTO
HandleTimerProg01 PROTO

ENDIF