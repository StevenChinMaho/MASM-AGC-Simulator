# MASM AGC Simulator

> 此專案仍在初期開發階段，絕大多數預期的 feature 都還沒有實做出來。

## 簡介

此專案是一個 MASM 期末專題，旨在使用 32-bit MASM 搭配 Irvine32 學習套件與 Windows API 來實現部分大幅簡化的 Apollo Guidance Computer (AGC) 發射倒入軌階段時的部分軌道計算行為及 DSKY 部分簡單操作邏輯。

## 緣起

此專案的目的為 MASM 練習，而非真正意義上的重構。儘管此專案的靈感來源於 NASA 開源的 AGC 程式碼，但 AGC 只有 16bit (15 data bits + 1 parity bit)，並且使用一補數來運算，原始碼對我來說太龐大也太難理解，並且跟課程所學習的 MASM 根本不是同種東西。因此我主要的開發手段是參考[Moonjs](https://www.svtsim.com/moonjs/agc.html)網站的AGC模擬器，試著使用自己的理解來模仿重現小部分的特性。

## 專案特性

使用 32bit MASM 實現軌道運算公式與輸出成果處理，並且能大致模仿輸入動名詞切換想監控的軌道參數模式。火箭當前的姿態與加速度向量等運算軌道所需要的資訊就用預先制好的表來查詢，目前預計希望能實現以下三種模式:

1. major mode 11 display

    R1 = velocity (XXXXX ft/s).

    R2 = the altitude rate (XXXXX ft/s).

    R3 = the altitude above the pad (XXXX.X nmi).

2. orbit parameters (V82E)

    R1 = the apocenter altitude (XXXX.X nmi).

    R2 = the pericenter altitude (XXXX.X nmi).

    R3 = the time to free fall (XX XX min:sec).

3. display time from perigee (V06N32E)

    R1 = 00XXX. hours

    R2 = 000XX. minutes

    R3 = 0XX.XX seconds

也就是說，大部分的指示燈都沒有實際用途。

## Prerequisites

1. Visual Studio
2. 安裝 `使用 C++ 的桌面開發 (Desktop development with C++)` 工作負載

## 安裝步驟 (使用VScode開發)

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

## 參考資料

- [Moonjs](https://svtsim.com/moonjs/agc.html)
- [Microsoft Learn](https://learn.microsoft.com/zh-tw/windows/win32/api/)
- [Wikipedia: Apollo Guidance Computer](https://en.wikipedia.org/wiki/Apollo_Guidance_Computer)
- [GitHub: chrislgarry/apollo-11](https://github.com/chrislgarry/apollo-11)
- [Keyboard, Display (DSKY), Apollo Guidance Computer](https://airandspace.si.edu/collection-objects/keyboard-display-dsky-apollo-guidance-computer/nasm_A19760744000)
