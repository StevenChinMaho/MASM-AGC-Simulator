import math
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider, Button

# ==========================================
# 物理常數與單位轉換
# ==========================================
G = 6.67430e-11
Me = 5.972e24
MU = G * Me
Re = 6371000.0
G0 = 9.80665

NMI_TO_M = 1852.0
FT_TO_M = 0.3048
M_TO_NMI = 1.0 / NMI_TO_M
M_TO_FT = 1.0 / FT_TO_M

# ==========================================
# 初始全域參數 (可透過滑桿修改)
# ==========================================
params = {
    'thrust_1': 34000e3,
    'thrust_2': 5000e3,
    'thrust_3': 1000e3,
    'pitch_162': 60.0,
    'pitch_400': 75.0,
    'pitch_540': 85.0
}

def get_pitch_at_time(t):
    PITCH_PROFILE = [
        (0, 0.0), (15, 0.0),
        (162, params['pitch_162']),
        (400, params['pitch_400']),
        (540, params['pitch_540']),
        (704, 90.0), (6000, 90.0)
    ]
    for i in range(len(PITCH_PROFILE) - 1):
        t1, p1 = PITCH_PROFILE[i]
        t2, p2 = PITCH_PROFILE[i+1]
        if t1 <= t <= t2:
            return p1 + (p2 - p1) * ((t - t1) / (t2 - t1))
    return PITCH_PROFILE[-1][1]

def calculate_orbital_elements(x, y, vx, vy):
    r = math.sqrt(x**2 + y**2)
    v2 = vx**2 + vy**2
    v_r = (x * vx + y * vy) / r
    h = x * vy - y * vx
    energy = (v2 / 2.0) - (MU / r)
    
    if energy >= 0: return 0, 0, -1

    a = -MU / (2.0 * energy)
    e2 = 1.0 + (2.0 * energy * h**2) / (MU**2)
    e = math.sqrt(max(0, e2))
    
    apogee_alt = a * (1.0 + e) - Re
    perigee_alt = a * (1.0 - e) - Re
    
    if perigee_alt >= 0:
        tff = -1.0
    else:
        try:
            cos_theta_c = (a * (1.0 - e**2) / r - 1.0) / e
            cos_theta_c = max(-1.0, min(1.0, cos_theta_c))
            theta_c = math.acos(cos_theta_c)
            if v_r < 0: theta_c = 2 * math.pi - theta_c
                
            cos_theta_i = (a * (1.0 - e**2) / Re - 1.0) / e
            cos_theta_i = max(-1.0, min(1.0, cos_theta_i))
            theta_i = 2 * math.pi - math.acos(cos_theta_i)
            
            E_c = math.acos( max(-1.0, min(1.0, (e + cos_theta_c) / (1 + e * cos_theta_c))) )
            if theta_c > math.pi: E_c = 2 * math.pi - E_c
            E_i = math.acos( max(-1.0, min(1.0, (e + cos_theta_i) / (1 + e * cos_theta_i))) )
            if theta_i > math.pi: E_i = 2 * math.pi - E_i
            
            M_c = E_c - e * math.sin(E_c)
            M_i = E_i - e * math.sin(E_i)
            if M_i < M_c: M_i += 2 * math.pi
            
            mean_motion = math.sqrt(MU / (a**3))
            tff = (M_i - M_c) / mean_motion
        except:
            tff = -1.0
            
    return apogee_alt, perigee_alt, tff

# ==========================================
# 核心積分引擎 (支援極值追蹤)
# ==========================================
def run_simulation(dt, mode="preview"):
    total_time = 5400 # 1.5 小時
    
    ROCKET_CONFIG = [
        {
            "name": "S-IC (Stage 1)",
            "t_start": 0, "t_end": 162,
            "thrust": params['thrust_1'],       # 34,000 kN (5具 F-1 引擎)
            "mass_initial": 2917000.0, # 起飛總重
            "mass_flow": 13178.0     # 耗油率 (kg/s)
        },
        {
            "name": "S-II (Stage 2)",
            "t_start": 162, "t_end": 540,
            "thrust": params['thrust_2'],        # 5,000 kN (5具 J-2 引擎)
            "mass_initial": 642000.0,  # 拋棄 S-IC 後的總重 (校正!)
            "mass_flow": 1210.0
        },
        {
            "name": "S-IVB (Stage 3)",
            "t_start": 540, "t_end": 704,            
            "thrust": params['thrust_3'],        # 1,000 kN (1具 J-2 引擎)
            "mass_initial": 166000.0,  # 拋棄 S-II 後的總重 (校正!)
            "mass_flow": 242.0
        }
    ]
    
    x, y = 0.0, Re
    vx, vy = 406.0, 0.0 
    
    plot_powered_x, plot_powered_y = [], []
    plot_inertial_x, plot_inertial_y = [], []
    records_N62, records_N44 = [], []
    
    final_ap, final_pe = 0, 0
    max_alt, t_max_alt, pos_max_alt = 0, 0, (0, 0)
    max_vel, t_max_vel, pos_max_vel = 0, 0, (0, 0)
    
    for t_step in range(int(total_time / dt) + 1):
        t = t_step * dt
        current_stage = next((s for s in ROCKET_CONFIG if s["t_start"] <= t < s["t_end"]), None)
                
        r = math.sqrt(x**2 + y**2)
        v_total = math.sqrt(vx**2 + vy**2)
        v_r = (x * vx + y * vy) / r
        alt = r - Re
        
        # --- 追蹤極值 ---
        if alt > max_alt:
            max_alt = alt
            t_max_alt = t
            pos_max_alt = (x, y)
        if v_total > max_vel:
            max_vel = v_total
            t_max_vel = t
            pos_max_vel = (x, y)
            
        ax, ay = - (MU / r**3) * x, - (MU / r**3) * y
        is_powered = False
        
        if current_stage:
            is_powered = True
            stage_t = t - current_stage["t_start"]
            mass = current_stage["mass_initial"] - current_stage["mass_flow"] * stage_t
            thrust = current_stage["thrust"]
            
            pitch = math.radians(get_pitch_at_time(t))
            acc_thrust = thrust / mass
            
            angle_radial = math.atan2(y, x)
            angle_thrust = angle_radial - pitch
            
            ax += acc_thrust * math.cos(angle_thrust)
            ay += acc_thrust * math.sin(angle_thrust)
            
        vx += ax * dt
        vy += ay * dt
        x += vx * dt
        y += vy * dt
        
        # 繪圖採樣 (Preview模式)
        if mode == "preview" and t_step % int(2 / dt) == 0:
            if is_powered:
                plot_powered_x.append(x)
                plot_powered_y.append(y)
            elif t_step % int(10 / dt) == 0: 
                plot_inertial_x.append(x)
                plot_inertial_y.append(y)
                
        # 捕捉 SECO (入軌) 的瞬間參數
        if abs(t - 704.0) < dt:
            ap_m, pe_m, _ = calculate_orbital_elements(x, y, vx, vy)
            final_ap = ap_m * M_TO_NMI
            final_pe = pe_m * M_TO_NMI

        # MASM 資料生成 (Export模式)
        if mode == "export" and t_step % int(2 / dt) == 0:
            ap_m, pe_m, tff_s = calculate_orbital_elements(x, y, vx, vy)
            
            v_ft = v_total * M_TO_FT
            hdot_ft = v_r * M_TO_FT
            alt_nmi = alt * M_TO_NMI
            ap_nmi, pe_nmi = ap_m * M_TO_NMI, pe_m * M_TO_NMI
            
            r1_62 = int(round(v_ft))
            r2_62 = int(round(hdot_ft))
            r3_62 = int(round(alt_nmi * 10))
            
            r1_44 = int(round(ap_nmi * 10)) if ap_nmi > 0 else 0
            r2_44 = int(round(pe_nmi * 10))
            
            if pe_nmi > 0 or tff_s < 0:
                r3_44 = -59059
            else:
                mins = min(99, int(tff_s // 60))
                secs = int(tff_s % 60)
                r3_44 = -(mins * 1000 + secs) 
                
            met_str = f"T+{int(t//60):02d}:{int(t%60):02d}"
            records_N62.append(f"        DWORD {r1_62}, {r2_62}, {r3_62}   ; MET {met_str}")
            records_N44.append(f"        DWORD {r1_44}, {r2_44}, {r3_44}   ; MET {met_str}")
            
    if mode == "preview":
        return plot_powered_x, plot_powered_y, plot_inertial_x, plot_inertial_y, final_ap, final_pe, max_alt, t_max_alt, pos_max_alt, max_vel, t_max_vel, pos_max_vel
    else:
        return records_N62, records_N44

# ==========================================
# 介面佈局 (圖表最大化設計)
# ==========================================
fig = plt.figure(figsize=(14, 8)) # 寬比例視窗
fig.canvas.manager.set_window_title("Apollo 11 AGC Trajectory Tuner")

# 左側：超大圖表區 (佔比寬度 65%)
ax = fig.add_axes([0.05, 0.05, 0.65, 0.9])

earth = plt.Circle((0, 0), Re, color='lightgreen', fill=True, alpha=0.5, label="Earth")
ax.add_artist(earth)

line_pow, = ax.plot([], [], color='red', linewidth=3, label="Powered Flight")
line_ine, = ax.plot([], [], color='blue', linewidth=1.5, linestyle='--', label="Parking Orbit")

# 極值標記 (初始化為空)
marker_alt, = ax.plot([], [], '^', color='purple', markersize=12, label="Max Altitude")
marker_vel, = ax.plot([], [], '*', color='orange', markersize=14, label="Max Velocity")

# 數據面板 (放置於圖表左上角)
text_orbit = ax.text(0.02, 0.02, '', transform=ax.transAxes, fontsize=8, family='monospace',
                     verticalalignment='bottom', bbox=dict(boxstyle='round', facecolor='white', alpha=0.5))

ax.set_aspect('equal')
limit = Re + 500000 
ax.set_xlim(-limit, limit)
ax.set_ylim(-limit, limit)
ax.grid(True, linestyle=':')
ax.legend(loc="lower right")

# ==========================================
# 右側：控制區 (滑桿與按鈕)
# ==========================================
axcolor = 'lightgoldenrodyellow'

# 推力控制 (右上角)
ax_th1 = fig.add_axes([0.78, 0.85, 0.18, 0.03], facecolor=axcolor)
ax_th2 = fig.add_axes([0.78, 0.75, 0.18, 0.03], facecolor=axcolor)
ax_th3 = fig.add_axes([0.78, 0.65, 0.18, 0.03], facecolor=axcolor)

# 姿態控制 (右中)
ax_p1 = fig.add_axes([0.78, 0.45, 0.18, 0.03], facecolor=axcolor)
ax_p2 = fig.add_axes([0.78, 0.35, 0.18, 0.03], facecolor=axcolor)
ax_p3 = fig.add_axes([0.78, 0.25, 0.18, 0.03], facecolor=axcolor)

# 建立滑桿
s_th1 = Slider(ax_th1, 'S-IC (kN)', 28000e3, 40000e3, valinit=params['thrust_1'], valstep=100e3)
s_th2 = Slider(ax_th2, 'S-II (kN)', 4000e3, 6000e3, valinit=params['thrust_2'], valstep=50e3)
s_th3 = Slider(ax_th3, 'S-IVB (kN)', 500e3, 1500e3, valinit=params['thrust_3'], valstep=10e3)

s_p1 = Slider(ax_p1, 'Pitch(162s)', 40.0, 90.0, valinit=params['pitch_162'], valstep=0.5)
s_p2 = Slider(ax_p2, 'Pitch(400s)', 50.0, 90.0, valinit=params['pitch_400'], valstep=0.5)
s_p3 = Slider(ax_p3, 'Pitch(540s)', 60.0, 90.0, valinit=params['pitch_540'], valstep=0.5)

# 將滑桿標籤稍微往左移，避免跟數值擠在一起
for s in [s_th1, s_th2, s_th3, s_p1, s_p2, s_p3]:
    s.label.set_position((-0.02, 0.5))
    s.label.set_horizontalalignment('right')

# 更新畫面事件
def update(val):
    params['thrust_1'] = s_th1.val
    params['thrust_2'] = s_th2.val
    params['thrust_3'] = s_th3.val
    params['pitch_162'] = s_p1.val
    params['pitch_400'] = s_p2.val
    params['pitch_540'] = s_p3.val
    
    px, py, ix, iy, f_ap, f_pe, max_alt, t_max_alt, pos_max_alt, max_vel, t_max_vel, pos_max_vel = run_simulation(dt=0.5, mode="preview")
    
    # 更新軌跡與極值座標
    line_pow.set_data(px, py)
    line_ine.set_data(ix, iy)
    marker_alt.set_data([pos_max_alt[0]], [pos_max_alt[1]])
    marker_vel.set_data([pos_max_vel[0]], [pos_max_vel[1]])
    
    # 更新數據面板文字
    status_text = (f"=== Parking Orbit (SECO) ===\n"
                   f"Apogee : {f_ap:7.1f} nmi\n"
                   f"Perigee: {f_pe:7.1f} nmi\n\n"
                   f"=== Flight Maxium Data ===\n"
                   f"Max Height: {max_alt * M_TO_NMI:6.1f} nmi (@ T+{int(t_max_alt//60):02d}:{int(t_max_alt%60):02d})\n"
                   f"Top Velocity: {max_vel * M_TO_FT:6.0f} ft/s (@ T+{int(t_max_vel//60):02d}:{int(t_max_vel%60):02d})")
                   
    if f_pe < 0:
        status_text += "\n\nWarning: Suborbital!"
    
    text_orbit.set_text(status_text)
    fig.canvas.draw_idle()

# 綁定事件
for s in [s_th1, s_th2, s_th3, s_p1, s_p2, s_p3]:
    s.on_changed(update)

update(None)

# ==========================================
# 匯出按鈕 (右下角)
# ==========================================
ax_btn = fig.add_axes([0.78, 0.08, 0.18, 0.06])
btn_export = Button(ax_btn, 'Export ASM Table', hovercolor='0.9')
btn_export.label.set_fontsize(12)
btn_export.label.set_weight('bold')

def export_data(event):
    print("⏳ 正在以高精度 (dt=0.1s) 運算並匯出 MASM 表格...")
    n62, n44 = run_simulation(dt=0.1, mode="export")
    max_idx = len(n62) - 1
    
    asm_content = f"""; ====================================================
; 阿波羅 11 號 發射至入軌 軌道參數表 (90分鐘, 每2秒一筆)
; ====================================================
INCLUDE Irvine32.inc
option casemap:none
INCLUDE Globals.inc

.data
    ; V06N62: R1 = 速率 (ft/s), R2 = 上升率 (ft/s), R3 = 高度 (nmi * 10)
    OrbitTableN62MaxIndex DWORD {max_idx}
    OrbitTableN62 \\
{chr(10).join(n62)}

    ; V16N44: R1 = 遠地點 (nmi * 10), R2 = 近地點 (nmi * 10), R3 = TFF (MM0SS / -59059)
    OrbitTableN44MaxIndex DWORD {max_idx}
    OrbitTableN44 \\
{chr(10).join(n44)}

END
"""
    with open("TrajectoryData.asm", "w", encoding="utf-8") as f:
        f.write(asm_content)
    print(f"✅ 成功寫入 TrajectoryData.asm！ 請回到 MASM 重新編譯專案。")

btn_export.on_clicked(export_data)

plt.show()