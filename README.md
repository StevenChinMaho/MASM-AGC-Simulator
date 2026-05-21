# MASM AGC Simulator

> 此專案仍在初期開發階段，絕大多數預期的 feature 都還沒有實做出來。

## 簡介

此專案是一個 MASM 期末專題，旨在使用 32-bit MASM 搭配 Irvine32 學習套件與 Windows API 來實現部分大幅簡化的 Apollo Guidance Computer (AGC) 發射倒入軌階段時的部分軌道計算行為及 DSKY 部分簡單操作邏輯。

## 緣起

此專案的目的為 MASM 練習，而非真正意義上的重構。儘管此專案的靈感來源於 NASA 開源的 AGC 程式碼，但 AGC 只有 16bit (15 data bits + 1 parity bit)，並且使用一補數來運算，原始碼對我來說太龐大也太難理解，並且跟課程所學習的 MASM 根本不是同種東西。因此我主要的開發手段是參考[Moonjs](https://www.svtsim.com/moonjs/agc.html)網站的AGC模擬器，試著使用自己的理解來模仿重現小部分的特性。

## 專案特性

使用 32bit MASM 實現軌道運算公式與輸出成果處理，並且能大致模仿輸入動名詞切換想監控的軌道參數模式。火箭當前的姿態與加速度向量等運算軌道所需要的資訊就用預先制好的表來查詢，目前預計希望能實現以下三種模式

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

## 參考資料

- [Moonjs](https://svtsim.com/moonjs/agc.html)
- [Microsoft Learn](https://learn.microsoft.com/zh-tw/windows/win32/api/)
- [Wikipedia: Apollo Guidance Computer](https://en.wikipedia.org/wiki/Apollo_Guidance_Computer)
- [GitHub: chrislgarry/apollo-11](https://github.com/chrislgarry/apollo-11)
- [Keyboard, Display (DSKY), Apollo Guidance Computer](https://airandspace.si.edu/collection-objects/keyboard-display-dsky-apollo-guidance-computer/nasm_A19760744000)
