#!/usr/bin/env python3
# NumberBlock 外观方案对比图。
# 配色/几何全部取自工程现有常量：
#   IsoFloor.BG / slot StyleBoxFlat / CubeEntity._draw / CardShard / EnergyBar / NumberBlock.tres
# 字体用工程自带的 Frick（数字）与 Noto CJK（说明文字）。
# 非引擎实渲，仅供方向选择。
from PIL import Image, ImageDraw, ImageFont
import math

S = 3
W, H = 760, 780

FRICK = "Assets/Fonts/Frick0.3-Regular-3.otf"
CJK = "/usr/share/fonts/google-noto-sans-cjk-fonts/NotoSansCJK-Regular.ttc"

BG         = (18, 19, 22)      # IsoFloor.BG  0.070,0.075,0.085
SLOT_BG    = (40, 38, 54)      # slot bg_color 0.157,0.149,0.212
SLOT_LINE  = (150, 150, 163)
ORANGE     = (255, 170, 61)    # NumberBlock.tres 1.0,0.667,0.239
ACCENT     = (255, 184, 107)   # CardShard.MARK_COLOR 1.0,0.72,0.42
SHARD_BODY = (77, 74, 94)      # CardShard.BODY_COLOR 0.235,0.227,0.306
NUM_DARK   = (59, 36, 19)      # NumberBlock label 0.231,0.141,0.075
TXT        = (242, 242, 245)
TXT_DIM    = (150, 152, 162)


def lc(c, a):      return tuple(round(v + (255 - v) * a) for v in c)
def dc(c, a):      return tuple(round(v * (1 - a)) for v in c)
def bl(fg, bg, a): return tuple(round(fg[i] * a + bg[i] * (1 - a)) for i in range(3))


def iso_hash(i, j, salt):
    n = (i * 92837111 + j * 689287499 + salt * 283923481) & 0x7FFFFFFF
    n = (n ^ (n >> 13)) & 0x7FFFFFFF
    n = (n * 1274126177) & 0x7FFFFFFF
    n = (n ^ (n >> 16)) & 0x7FFFFFFF
    return n / 0x7FFFFFFF


img = Image.new("RGB", (W * S, H * S), BG)
d = ImageDraw.Draw(img)
f_title = ImageFont.truetype(CJK, 25 * S)
f_sub   = ImageFont.truetype(CJK, 14 * S)
f_label = ImageFont.truetype(CJK, 21 * S)
f_note  = ImageFont.truetype(CJK, 13 * S)


def P(pts): return [(x * S, y * S) for x, y in pts]


def rr(x0, y0, x1, y1, r, fill=None, outline=None, width=1):
    d.rounded_rectangle([x0*S, y0*S, x1*S, y1*S], radius=r*S,
                        fill=fill, outline=outline, width=max(1, int(width*S)))


def line(pts, fill, width=1):
    d.line(P(pts), fill=fill, width=max(1, int(width*S)), joint="curve")


def txt(xy, s, font, fill, anchor="la", stroke=0, sfill=None):
    d.text((xy[0]*S, xy[1]*S), s, font=font, fill=fill, anchor=anchor,
           stroke_width=int(stroke*S), stroke_fill=sfill)


def frick(px): return ImageFont.truetype(FRICK, int(px * S))


def slot(x, y, w=64):
    rr(x, y, x + w, y + w, 8, fill=SLOT_BG,
       outline=bl(SLOT_LINE, SLOT_BG, 0.45), width=1)


# ---------------- A 等轴测骰子（复刻 CubeEntity._draw） ----------------
def draw_cube(cx, cy, size, color, number):
    hw, qh, dep = size * 0.5, size * 0.25, size * 0.5
    t_n, t_e, t_s, t_w = (0, -dep - qh), (hw, -dep), (0, -dep + qh), (-hw, -dep)
    b_e, b_s, b_w = (hw, 0), (0, qh), (-hw, 0)
    A = lambda p: (cx + p[0], cy + p[1])
    hull = [t_n, t_e, b_e, b_s, b_w, t_w]
    cen = (0, -dep * 0.5)
    for ring in range(3, 0, -1):
        pts = [(cen[0] + (p[0] - cen[0]) * (1 + 0.09 * ring),
                cen[1] + (p[1] - cen[1]) * (1 + 0.09 * ring)) for p in hull]
        d.polygon(P([A(p) for p in pts]), fill=bl(lc(color, 0.5), SLOT_BG, 0.10 * ring / 3.0))
    d.polygon(P([A(p) for p in (t_n, t_e, t_s, t_w)]), fill=lc(color, 0.30))
    d.polygon(P([A(p) for p in (t_w, t_s, b_s, b_w)]), fill=dc(color, 0.45))
    d.polygon(P([A(p) for p in (t_s, t_e, b_e, b_s)]), fill=dc(color, 0.15))
    line([A(p) for p in (t_n, t_e, b_e, b_s, b_w, t_w, t_n)],
         bl(lc(color, 0.55), SLOT_BG, 0.55), 0.8)
    txt((cx, cy - dep), str(number), frick(size * 0.40), lc(color, 0.85),
        anchor="mm", stroke=0.7, sfill=dc(color, 0.6))


# ---------------- B 刀身碎片（复刻 CardShard._wobbled_outline） ----------------
def draw_shard(cx, cy, box, number, variant):
    SHARD = [(-58, -56), (2, -56), (60, 0), (2, 56), (-58, 56)]
    k = box / 118.0
    seg, n = 6, len(SHARD)
    pts = []
    for e in range(n):
        a, b = SHARD[e], SHARD[(e + 1) % n]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = (dx * dx + dy * dy) ** 0.5
        perp = (-dy / L, dx / L)
        bend = iso_hash(e, variant, 40) * 2 - 1
        for s in range(seg + 1):
            t = s / seg
            w = math.sin(t * math.pi) * bend * 2.2
            pts.append((a[0] + dx * t + perp[0] * w, a[1] + dy * t + perp[1] * w))
    A = lambda p: (cx + p[0] * k, cy + p[1] * k)
    body = lc(SHARD_BODY, 0.10)
    d.polygon(P([A(p) for p in pts]), fill=body)
    d.line(P([A(p) for p in pts] + [A(pts[0])]),
           bl(ACCENT, body, 0.80), width=max(1, int(1.0 * S)), joint="curve")
    txt((cx + 4 * k, cy), str(number), frick(box * 0.40), ACCENT,
        anchor="mm", stroke=0.5, sfill=(30, 26, 40))


# ---------------- C 菱形宝石（复刻 EnergyBar._draw_pip） ----------------
def draw_gem(cx, cy, w, color, number):
    hw, qh = w * 0.5, w * 0.25
    dia = [(0, -qh), (hw, 0), (0, qh), (-hw, 0)]
    A = lambda p: (cx + p[0], cy + p[1])
    for ring in range(3, 0, -1):
        pts = [(p[0] * (1 + 0.18 * ring), p[1] * (1 + 0.18 * ring)) for p in dia]
        d.polygon(P([A(p) for p in pts]), fill=bl(color, SLOT_BG, 0.20 * ring / 3.0))
    d.polygon(P([A(p) for p in dia]), fill=color)
    line([A(p) for p in dia + [dia[0]]], lc(color, 0.5), 1.5)
    txt((cx, cy), str(number), frick(w * 0.34), NUM_DARK, anchor="mm")


# ---------------- D 扁平实体化 ----------------
def draw_flat(cx, cy, size, number):
    h = size * 0.5
    rr(cx - h + 5, cy - h + 6, cx + h + 5, cy + h + 6, 12, fill=dc(ORANGE, 0.80))
    rr(cx - h, cy - h, cx + h, cy + h, 12, fill=ORANGE)
    line([(cx - h + 9, cy - h + 3), (cx + h - 9, cy - h + 3)], lc(ORANGE, 0.45), 2)
    line([(cx - h + 9, cy + h - 3), (cx + h - 9, cy + h - 3)], dc(ORANGE, 0.35), 2)
    rr(cx - h, cy - h, cx + h, cy + h, 12, outline=lc(ORANGE, 0.50), width=2)
    txt((cx, cy), str(number), frick(size * 0.58), NUM_DARK, anchor="mm")


# ============================ 版面 ============================
txt((28, 22), "NumberBlock 外观方案（示意）", f_title, TXT)
txt((28, 56), "配色 / 几何 / 字体均取自工程现有常量 · 非引擎实渲 · 仅用于选方向", f_sub, TXT_DIM)
line([(28, 84), (W - 28, 84)], (52, 54, 62), 1)

ROWS = [
    ("A", "等轴测骰子",
     "复刻 CubeEntity：与玩家/敌人/地面同一套三面体，世界感最统一。代价是数字只有顶面 64x32 可放，须缩到 ~26px，斜边会让数字显得被压扁。"),
    ("B", "刀身碎片",
     "复刻 CardShard：与运算块同族，暗紫体 + 橙色描边 + 橙色数字。正好用上「橙=伤害」这个已有语义色，和手牌拼在一起时叙事最顺。"),
    ("C", "菱形宝石",
     "复刻 EnergyBar / 地砖：2:1 等轴测菱形 + 三圈辉光，桌游感最强。但 64 宽只有 32 高，数字要压到 ~22px，方形槽位还会空出四角。"),
    ("D", "扁平实体化",
     "保留方形只补体积：启用已存在但 visible=false 的 Shadow 做投影、去掉 5px 纯黑边、圆角 12 对齐主题、数字加描边。改动最小、可读性最好。"),
]
row_h, top = 162, 104

for idx, (tag, name, note) in enumerate(ROWS):
    y0 = top + idx * row_h
    yc = y0 + row_h // 2 - 6
    if idx:
        line([(28, y0 - 6), (W - 28, y0 - 6)], (44, 46, 54), 1)

    txt((28, yc - 56), tag, f_label, ACCENT)
    txt((52, yc - 54), name, f_label, TXT)

    cur, lines = "", []
    for ch in note:
        if d.textlength(cur + ch, font=f_note) > 258 * S and cur:
            lines.append(cur); cur = ch
        else:
            cur += ch
    lines.append(cur)
    for i, ln in enumerate(lines[:5]):
        txt((28, yc - 22 + i * 19), ln, f_note, TXT_DIM)

    for i, v in enumerate((3, 7, 9)):
        sx = 322 + i * 76
        slot(sx, yc - 32)
        cx = sx + 32
        if tag == "A":     draw_cube(cx, yc + 14, 62, ORANGE, v)
        elif tag == "B":   draw_shard(cx, yc, 60, v, 1 + i * 3)
        elif tag == "C":   draw_gem(cx, yc - 4, 60, ORANGE, v)
        else:              draw_flat(cx, yc, 60, v)

    txt((572, yc - 50), "↙ operand 内 (×0.63)", f_note, TXT_DIM)
    for i, v in enumerate((4, 8)):
        sx, cx, cy2 = 582 + i * 46, 582 + i * 46 + 20, yc + 4
        if tag == "A":     draw_cube(cx, cy2 + 9, 39, ORANGE, v)
        elif tag == "B":   draw_shard(cx, cy2, 38, v, 2 + i * 5)
        elif tag == "C":   draw_gem(cx, cy2 - 3, 38, ORANGE, v)
        else:              draw_flat(cx, cy2, 38, v)

img.resize((W, H), Image.LANCZOS).save(".mockups/nb_options.png")
print("saved .mockups/nb_options.png")
