#!/usr/bin/env python3
# socket_shard.gd + number_shard.gd 的镜像渲染：
# buffer 槽位与运算块 operand 凹槽，都放在真实尺寸里。非引擎实渲。
import math, random
from PIL import Image, ImageDraw, ImageFont

S = 3
SHARD = [(-31, -30), (9, -30), (31, 0), (9, 30), (-31, 30)]
NUMBER_CENTER = (-5.1, 0.0)

BODY_COOL, BODY_HOT = (0.216, 0.208, 0.271), (0.361, 0.306, 0.322)
RIM_COOL, RIM_HOT = (1.0, 0.72, 0.42, 0.50), (1.0, 0.84, 0.48, 1.0)
GLOW_HOT = 0.42
DIGIT_SIZE, DIGIT_BOX = 38.0, 64.0
DIGIT_ALPHA_COOL, DIGIT_ALPHA_HOT = 0.75, 1.0
WOBBLE, SEGMENTS = 2.2, 6

PIT = (0.098, 0.090, 0.125)
EDGE_FAR = (0.784, 0.784, 0.831, 0.12)
EDGE_NEAR = (0.784, 0.784, 0.831, 0.42)
SOCKET_WOBBLE, SOCKET_VARIANT, NEAR_EDGES = 1.2, 0, (2, 3)

BLADE = [(-58, -56), (2, -56), (60, 0), (2, 56), (-58, 56)]
BLADE_BODY, BLADE_EDGE = (0.235, 0.227, 0.306), (0.784, 0.784, 0.831, 0.72)

BG, DIGIT_OUTLINE = (18, 19, 22), (33, 31, 44)
FRICK = "Assets/Fonts/Frick0.3-Regular-3.otf"
CJK = "/usr/share/fonts/google-noto-sans-cjk-fonts/NotoSansCJK-Regular.ttc"

W, H = 800, 470
img = Image.new("RGB", (W * S, H * S), BG)
d = ImageDraw.Draw(img)
P = lambda pts: [(x * S, y * S) for x, y in pts]


def iso_hash(i, j, salt):
    n = (i * 92837111 + j * 689287499 + salt * 283923481) & 0x7FFFFFFF
    n = (n ^ (n >> 13)) & 0x7FFFFFFF
    n = (n * 1274126177) & 0x7FFFFFFF
    n = (n ^ (n >> 16)) & 0x7FFFFFFF
    return n / 0x7FFFFFFF


def outline(poly, wob, seg, variant):
    pts, n = [], len(poly)
    for e in range(n):
        a, b = poly[e], poly[(e + 1) % n]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy)
        perp = (-dy / L, dx / L)
        bend = iso_hash(e, variant, 40) * 2 - 1
        for s in range(seg + 1):
            u = s / seg
            w = math.sin(u * math.pi) * bend * wob
            pts.append((a[0] + dx * u + perp[0] * w, a[1] + dy * u + perp[1] * w))
    return pts


def lc(c, a): return tuple(round(v + (255 - v) * a) for v in c)
def mix(c1, c2, t): return tuple(c1[i] + (c2[i] - c1[i]) * t for i in range(len(c1)))
def blend(fg, bg, a): return tuple(round(fg[i] * a + bg[i] * (1 - a)) for i in range(3))
def rgb(c): return tuple(round(v * 255) for v in c[:3])


def tier(v): return max(0.0, min(1.0, (v - 1) / 8.0))


def draw_socket(cx, cy, shape_scale):
    """socket_shard.gd._draw 的镜像"""
    pts = [(cx + p[0] * shape_scale, cy + p[1] * shape_scale)
           for p in outline(SHARD, SOCKET_WOBBLE, SEGMENTS, SOCKET_VARIANT)]
    d.polygon(P(pts), fill=rgb(PIT))
    d.line(P(pts + [pts[0]]), fill=rgb(EDGE_FAR), width=max(1, int(S)), joint="curve")
    step = SEGMENTS + 1
    for e in NEAR_EDGES:
        seg = pts[e * step:(e + 1) * step + 1]
        d.line(P(seg), fill=rgb(EDGE_NEAR), width=max(1, int(S)), joint="curve")


def draw_token(cx, cy, value, variant, k=1.0):
    """number_shard.gd._draw 的镜像"""
    t = tier(value)
    s = k
    pts = [(cx + p[0] * s, cy + p[1] * s) for p in outline(SHARD, WOBBLE, SEGMENTS, variant)]
    rim = mix(RIM_COOL, RIM_HOT, t)
    body = mix(BODY_COOL, BODY_HOT, t)
    for ring in (3, 2, 1):
        a = GLOW_HOT * t * 0.16 * ring / 3.0
        if a <= 0: continue
        gp = [(cx + p[0] * (1 + 0.10 * ring), cy + p[1] * (1 + 0.10 * ring)) for p in pts]
        d.polygon(P([(gx, gy) for gx, gy in gp]), fill=blend(rgb(rim), PIT, a))
    d.polygon(P(pts), fill=rgb(body))
    d.line(P(pts + [pts[0]]), fill=blend(rgb(rim), rgb(body), rim[3]),
           width=max(1, int((1.0 + 1.4 * t) * S)), joint="curve")
    size = DIGIT_SIZE
    f = ImageFont.truetype(FRICK, max(1, int(size * s * S)))
    asc, desc = f.getmetrics()
    baseline = cy + (NUMBER_CENTER[1] + (asc - desc) / 2.0) * s
    px = cx + NUMBER_CENTER[0] * s
    da = DIGIT_ALPHA_COOL + (DIGIT_ALPHA_HOT - DIGIT_ALPHA_COOL) * t
    d.text((px * S, baseline * S), str(value), font=f, fill=rgb(rim) + (round(da * 255),),
           anchor="ms", stroke_width=max(1, int(round(2 + 2 * t) * s * S * 0.5)),
           stroke_fill=DIGIT_OUTLINE)


def draw_blade(cx, cy, variant):
    pts = [(cx + p[0], cy + p[1]) for p in outline(BLADE, 2.2, SEGMENTS, variant)]
    d.polygon(P(pts), fill=rgb(BLADE_BODY))
    d.line(P(pts + [pts[0]]), fill=rgb(BLADE_EDGE), width=max(1, int(S)), joint="curve")
    for a, b in (((-11, -4), (-1, -4)), ((-11, 4), (-1, 4))):
        d.line(P([(cx + a[0], cy + a[1]), (cx + b[0], cy + b[1])]),
               fill=rgb((0.55, 0.48, 0.70)), width=max(1, int(S)))


f_t = ImageFont.truetype(CJK, 24 * S)
f_s = ImageFont.truetype(CJK, 14 * S)
f_l = ImageFont.truetype(CJK, 15 * S)
d.text((28 * S, 20 * S), "凹槽改造：buffer 槽位 + operand 槽位", font=f_t, fill=(242, 242, 245))
d.text((28 * S, 54 * S), "凹槽复用数字碎片的同一份轮廓（NumberShard.build_outline）· 洞比碎片大半圈 · 非引擎实渲",
       font=f_s, fill=(150, 152, 162))
d.line(P([(28, 80), (W - 28, 80)]), fill=(52, 54, 62), width=S)

random.seed(7)
d.text((28 * S, 94 * S), "buffer 4 格（64px，间距 12）· 最右一格空着，能看到凹槽本身；四格等大", font=f_l, fill=(150, 152, 162))
values = [3, 7, 2, None]
for i, v in enumerate(values):
    sx, cy = 50 + i * 76, 170
    draw_socket(sx + 32, cy, 1.08)
    if v is not None:
        draw_token(sx + 32, cy, v, random.randint(0, 999))

d.line(P([(28, 236), (W - 28, 236)]), fill=(44, 46, 54), width=S)
d.text((28 * S, 250 * S), "运算块的两个 operand（40px 面板，shape_scale 0.7）· 上面已填、下面空", font=f_l, fill=(150, 152, 162))
bcx, bcy = 170, 360
draw_blade(bcx, bcy, 5)
for oy, filled in ((-30, 6), (30, None)):
    ox, oyy = bcx - 32, bcy + oy
    draw_socket(ox, oyy, 0.70)
    if filled is not None:
        draw_token(ox, oyy, filled, random.randint(0, 999), k=0.63)

for i, line in enumerate([
    "凹槽现在是碎片的同形轮廓，不再是圆角方块。",
    "填色比战场底色更暗，读起来是凹进去的；洞壁下侧迎光、上侧背光。",
    "描边压到 0.12 / 0.42，洞只负责标位置，主角留给碎片。",
    "两个 operand 用同一个脚本、只改 shape_scale，不再各留一份 StyleBox。",
]):
    d.text((330 * S, (285 + i * 26) * S), line, font=f_s, fill=(150, 152, 162))

img.resize((W, H), Image.LANCZOS).save(".mockups/nb_sockets.png")
print("saved .mockups/nb_sockets.png")
