# MASM AGC Simulator

## 簡介

此專案是一個 MASM 期末專題，旨在使用 32-bit MASM 結合 Irvine32 學習套件與 Windows API 來實現簡化版 Apollo Guidance Computer (AGC) 發射與入軌階段部分軌道計算行為及 DSKY 動名詞指令系統。

## 緣起

此專案的目的為 MASM 練習，儘管此專案的靈感來源於 NASA 開源的 AGC 程式碼，但 AGC 只有 16bit (15 data bits + 1 parity bit)，並且使用一補數來運算，原始碼對我來說過於龐大，並且跟課程所學習的 MASM 相差甚遠。因此我主要的開發手段是參考[Moonjs](https://www.svtsim.com/moonjs/agc.html)網站的AGC模擬器，試著使用自己的理解來模擬小部分的特性的重現。

## 專案特色

使用 32bit MASM 實現 AGC 操作與輸出處理，結合 Windows API 達成穩時鐘訊號與非同步計算，並且能模擬輸入動名詞切換不同軌道參數模式監控。火箭當前的速度與軌道資訊使用預先制好的表來查詢。

### 鍵盤 DSKY 映射表

| 電腦鍵盤 | 對應 DSKY 按鍵 | 作用 |
| ------- | ------------- | ---- |
| `V / N` | Verb / Noun | 進入 VERB/NOUN 輸入模式，KEY REL 指示燈會亮起 |
| `0 - 9` | Digits | 輸入數字 |
| `E` | Enter | 完成輸入 |
| `P` | PRO (Proceed) | 返回主監控介面 |
| `C` | CLR (Clear) | 清除輸入緩衝區 |
| `K` | KEY REL (Release) | 取消輸入模式 |
| `R` | RSET (Reset ERR) | 重置 OPR ERR (指令錯誤) 指示燈 |
| `Enter` | Start PROG 11 (發射) | 火箭點火發射，AGC 自動進入 PROG 11 |

介面右側兩行時鐘分別代表 "開始時間 (Start Time)" 與 "任務經過時間 (Mission Elapsed Time)。

### 發射檢查表

1. 輸入指令 `V37E01E` 進入 PROG 01 (發射前初始化)。

2. 初始化慣性測量單元 (IMU)，等待 5 秒左右，確認 NO ATT 指示燈關閉。

3. 初始化結束後，AGC 會自動切換至 PROG 02 (等待發射階段)。

4. 在 PROG 02 中按下 ENTER (電腦鍵盤，不是 DSKY) 即可發射，並自動切換至 PROG 11。

5. 在 PROG 11 發射階段預設顯示以下監控資訊 (VERB 06, NOUN 62):

    R1 = 速率 (XXXXX ft/s).

    R2 = 上升率 (XXXXX ft/s).

    R3 = 高度 (XXXX.X nmi).

6. 在 PROG 11 發射階段可以輸入指令 `V82E` 監控軌道參數 (NOUN 44)

    R1 = 遠地點高度 (apogee) (XXXX.X nmi).

    R2 = the pericenter altitude (XXXX.X nmi).

    R3 = the time to free fall (XX XX min:sec).

7. 輸入指令 `V16N65E` 監控 AGC 開機時間

    R1 = 00XXX. 小時

    R2 = 000XX. 分鐘

    R3 = 0XX.XX 秒數

按下 `PRO` 鍵可以返回 VERB 06 NOUN 62 主監控。

另外，輸入指令 `V35E` 可運行燈泡測試

## 安裝步驟 (使用VScode開發)

### Prerequisites

1. Visual Studio
2. 安裝 `使用 C++ 的桌面開發 (Desktop development with C++)` 工作負載

### 一、下載並安裝 Irvine 套件

網路搜尋 `Irvine32` 或至[此網頁](https://www.asmirvine.com/gettingStartedVS2017/index.htm)下載 `Irvine.zip`，並解壓縮到 `C:\` 目錄中，您的目錄結構應該會長這樣 (注意大小寫):

```text
C:\
├── irvine
│   ├── Irvine32.inc
│   ├── Irvine32.lib
│   └── ...
└── ...
```

您也可以放在自己喜歡的目錄，但必須根據您自身的目錄去修改 `tasks.json` 的 `command`，注意有兩處需要修改。

### 二、匯入環境變數

由於編譯程式碼需要 Visual Studio 用於開發 C/C++ 自帶的環境變數 (例如 `ml.exe` 與 `link.exe` 等)，我們需要使用一些特殊手段才能在 VScode 中套用。

於 Windows 工作列搜尋 `x86 Native Tools Command Prompt for VS` 並執行，並在該黑畫面中輸入 `code .`，按下 Enter 後就會開啟 VScode，此 VScode 就會套用編譯 MASM 所需的環境變數。

開啟 VScode 後可以透過在終端機輸入指令 `ml` 測試環境變數:

```pwsh
PS C:\MASM-AGC-Simulator> ml
Microsoft (R) Macro Assembler Version 14.51.36244.0
Copyright (C) Microsoft Corporation.  All rights reserved.

usage: ML [ options ] filelist [ /link linkoptions]
Run "ML /help" or "ML /?" for more info
```

若有成功回傳此訊息，表示環境變數有成功加入，即可進入下一步驟。

> 注意: 要編譯並執行此專案必須每次都使用此方式開啟 VScode。

### 三、編譯並執行

在 VScode 中開啟此專案目錄，按下 F5 即可編譯並執行。

預設的 VScode 設定下可能會無法使用 `.asm` 中斷點的功能，按下 `Ctrl`+`,` (或點擊左下齒輪並點 `Settings`)，搜尋 `allowBreakpointsEverywhere` 並打勾，即可使用中斷點。

## 常見問題

### 程式碼無法編譯，找不到 `ml.exe`

編譯顯示錯誤訊息: `ml.exe: The term 'ml.exe' is not recognized as a name of a cmdlet, function, script file, or executable program.`。

**解決方法**: 關閉 VScode，搜尋 `x86 Native Tools Command Prompt for VS` 並執行，輸入 `code .` 來開啟 VScode。

### 無法使用中斷點

**解決方法**: 按下 `Ctrl`+`,` (或點擊左下齒輪並點 `Settings`)，搜尋 `allowBreakpointsEverywhere` 並打勾，即可使用中斷點。

## 已知未修復問題

- 燈泡檢查模式下，數字顯示器會被資料更新覆蓋。
- 在非 PROG 11 中下進入開機時間監控模式會導致 VERB 與 NOUN 被不當修改。

## 參考資料

- [Moonjs](https://svtsim.com/moonjs/agc.html)
- [Microsoft Learn](https://learn.microsoft.com/zh-tw/windows/win32/api/)
- [Wikipedia: Apollo Guidance Computer](https://en.wikipedia.org/wiki/Apollo_Guidance_Computer)
- [GitHub: chrislgarry/apollo-11](https://github.com/chrislgarry/apollo-11)
- [Keyboard, Display (DSKY), Apollo Guidance Computer](https://airandspace.si.edu/collection-objects/keyboard-display-dsky-apollo-guidance-computer/nasm_A19760744000)
