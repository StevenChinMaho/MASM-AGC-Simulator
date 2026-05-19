CreateThread PROTO,
    lpThreadAttributes:DWORD,
    dwStackSize:DWORD,
    lpStartAddress:DWORD,
    lpParameter:DWORD,
    dwCreationFlags:DWORD,
    lpThreadId:DWORD

CreateWaitableTimerA PROTO,
    lpTimerAttributes:DWORD,
    bManualReset:DWORD,
    lpTimerName:DWORD
IFNDEF __UNICODE__
    CreateWaitableTimer equ <CreateWaitableTimerA>
ENDIF

CreateWaitableTimerW PROTO,
    lpTimerAttributes:DWORD,
    bManualReset:DWORD,
    lpTimerName:DWORD
IFDEF __UNICODE__
    CreateWaitableTimer equ <CreateWaitableTimerW>
ENDIF

SetWaitableTimer PROTO,
    hTimer:DWORD,
    lpDueTime:PTR QWORD,  ; 傳遞 64 位元時間結構的指標
    lPeriod:DWORD,
    pfnCompletionRoutine:DWORD,
    lpArgToCompletionRoutine:DWORD,
    fResume:DWORD

WaitForSingleObject PROTO,
    hHandle:DWORD,
    dwMilliseconds:DWORD

WaitForMultipleObjects PROTO,
    nCount:DWORD,
    lpHandles:DWORD,
    bWaitAll:DWORD,
    dwMilliseconds:DWORD

CreateEventA PROTO,
    lpEventAttributes:DWORD,
    bManualReset:DWORD,
    bInitialState:DWORD,
    lpName:DWORD
IFNDEF __UNICODE__
    CreateEvent equ <CreateEventA>
ENDIF

CreateEventW PROTO,
    lpEventAttributes:DWORD,
    bManualReset:DWORD,
    bInitialState:DWORD,
    lpName:DWORD
IFDEF __UNICODE__
    CreateEvent equ <CreateEventW>
ENDIF

SetEvent PROTO, hEvent:DWORD

CloseHandle PROTO, hObject:DWORD

ExitThread PROTO, dwExitCode:DWORD

SetConsoleOutputCP PROTO, wCodePageID:DWORD

; 定義 Windows 常數
INFINITE EQU 0FFFFFFFFh