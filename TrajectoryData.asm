INCLUDE Irvine32.inc
option casemap:none
INCLUDE Globals.inc

.data
    ; ====================================================
    ; V06N62 軌道參數表 (例如：絕對速度, 垂直速度, 高度)
    ; ====================================================
    OrbitTableN62MaxIndex DWORD 10   
    OrbitTableN62 \
        DWORD 25000, 1500, 120   ; Index 0:  T+0s
        DWORD 25050, 1520, 125   ; Index 1:  T+2s
        DWORD 25100, 1540, 130   ; Index 2:  T+4s
        DWORD 25150, 1560, 135   ; Index 3:  T+6s
        DWORD 25200, 1580, 140   ; Index 4:  T+8s
        DWORD 25250, 1600, 145   ; Index 5:  T+10s
        DWORD 25300, 1620, 150   ; Index 6:  T+12s
        DWORD 25350, 1640, 155   ; Index 7:  T+14s
        DWORD 25400, 1660, 160   ; Index 8:  T+16s
        DWORD 25450, 1680, 165   ; Index 9:  T+18s
        DWORD 25500, 1700, 170   ; Index 10: T+20s

    ; ====================================================
    ; V16N44 軌道參數表 (例如：遠地點, 近地點, 未來規劃)
    ; ====================================================
    OrbitTableN44MaxIndex DWORD 10
    OrbitTableN44 \
        DWORD 18500, 18500, 0    ; Index 0:  T+0s
        DWORD 18600, 18500, 5    ; Index 1:  T+2s
        DWORD 18700, 18500, 10   ; Index 2:  T+4s
        DWORD 18800, 18500, 15   ; Index 3:  T+6s
        DWORD 18900, 18500, 20   ; Index 4:  T+8s
        DWORD 19000, 18500, 25   ; Index 5:  T+10s
        DWORD 19100, 18500, 30   ; Index 6:  T+12s
        DWORD 19200, 18500, 35   ; Index 7:  T+14s
        DWORD 19300, 18500, 40   ; Index 8:  T+16s
        DWORD 19400, 18500, 45   ; Index 9:  T+18s
        DWORD 19500, 18500, 50   ; Index 10: T+20s

END