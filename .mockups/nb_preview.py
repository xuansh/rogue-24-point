#!/usr/bin/env python3
# number_shard.gd 的 Python 镜像：一方面验算常量（凸性/内部/尺寸上界/分档单调），
# 一方面按同一套公式渲染最终效果预览。
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


def tier(v): return max(0.0, min(1.0, (v - 1) / 8.0))


def iso_hash(i, j, salt):
    n = (i * 92837111 + j * 689287499 + salt * 283923481) & 0x7FFFFFFF
    n = (n ^ (n >> 13)) & 0x7FFFFFFF
    n = (n * 1274126177) & 0x7FFFFFFF
    n = (n ^ (n >> 16)) & 0x7FFFFFFF
    return n / 0x7FFFFFFF


def wobbled(variant):
    pts, n = [], len(SHARD)
    for e in range(n):
        a, b = SHARD[e], SHARD[(e + 1) % n]
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy)
        perp = (-dy / L, dx / L)
        bend = iso_hash(e, variant, 40) * 2 - 1
        for s in range(SEGMENTS + 1):
            u = s / SEGMENTS
            w = math.sin(u * math.pi) * bend * WOBBLE
            pts.append((a[0] + dx * u + perp[0] * w, a[1] + dy * u + perp[1] * w))
    return pts


# ------------------------- 常量验算 -------------------------
def cross(o, a, b): return (a[0]-o[0])*(b[1]-o[1]) - (a[1]-o[1])*(b[0]-o[0])


def convex(poly):
    w = 0
    for i in range(len(poly)):
        c = cross(poly[i], poly[(i+1) % len(poly)], poly[(i+2) % len(poly)])
        if abs(c) < 1e-4: continue
        t = 1 if c > 0 else -1
        if w and t != w: return False
        w = t
    return True


def inside(poly, p):
    w = 0
    for i in range(len(poly)):
        c = cross(poly[i], poly[(i+1) % len(poly)], p)
        if abs(c) < 1e-4: continue
        side = 1 if c > 0 else -1
        if w and side != w: return False
        w = side
    return True


def verify():
    assert convex(SHARD), "SHARD 必须凸"
    assert inside(SHARD, NUMBER_CENTER), "NUMBER_CENTER 必须在碎片内"
    out = wobbled(7)
    step = SEGMENTS + 1
    for e in range(len(SHARD)):
        assert abs(out[e*step][0] - SHARD[e][0]) < 1e-5 and abs(out[e*step][1] - SHARD[e][1]) < 1e-5, "角点必须落回"
    assert abs(out[-1][0] - SHARD[0][0]) < 1e-5, "收笔必须回到起点"
    reach = max(max(abs(p[0]), abs(p[1])) for p in SHARD) + WOBBLE
    assert reach <= 38.0, f"越界 {reach}"
    # 尺寸契约：几何必须与值无关
    assert wobbled(3) == wobbled(3), "轮廓必须稳定"
    prev = -1.0
    for v in range(1, 10):
        t = tier(v)
        assert t >= prev, "分档必须单调"
        prev = t
    assert tier(1) == 0.0 and tier(9) == 1.0
    assert tier(0) == 0.0 and tier(99) == 1.0
    print(f"number shard ok: reach={reach:.2f}px (limit 38.0), tier(1..9) monotonic")


# ------------------------- 渲染 -------------------------
BG = (18, 19, 22)
SLOT_BG = (40, 38, 54)
SLOT_LINE = (150, 150, 163)
DIGIT_OUTLINE = (33, 31, 44)
FRICK = "Assets/Fonts/Frick0.3-Regular-3.otf"
CJK = "/usr/share/fonts/google-noto-sans-cjk-fonts/NotoSansCJK-Regular.ttc"

W, H = 800, 400
img = Image.new("RGB", (W * S, H * S), BG)
d = ImageDraw.Draw(img)
P = lambda pts: [(x * S, y * S) for x, y in pts]


def col(c, a=1.0):
    alpha = c[3] if len(c) > 3 else a
    return (round(c[0] * 255), round(c[1] * 255), round(c[2] * 255), round(alpha * 255))


def lc(c, a): return tuple(round(v + (255 - v) * a) for v in c)


def mix(c1, c2, t):
    return tuple(c1[i] + (c2[i] - c1[i]) * t for i in range(len(c1)))


def blend(fg, bg, a):
    return tuple(round(fg[i] * a + bg[i] * (1 - a)) for i in range(3))


def draw_shard(cx, cy, value, variant, k=1.0):
    t = tier(value)
    s = k
    pts = wobbled(variant)
    A = lambda p: (cx + p[0] * s, cy + p[1] * s)
    rim = mix(RIM_COOL, RIM_HOT, t)
    rim_rgb = col(rim)
    body = mix(BODY_COOL, BODY_HOT, t)
    body_rgb = tuple(round(v * 255) for v in body)

    for ring in (3, 2, 1):
        a = GLOW_HOT * t * 0.16 * ring / 3.0
        if a <= 0: continue
        gp = [(p[0]*(1 + 0.10*ring), p[1]*(1 + 0.10*ring)) for p in pts]
        d.polygon(P([A(p) for p in gp]), fill=blend(rim_rgb, SLOT_BG, a))

    d.polygon(P([A(p) for p in pts]), fill=body_rgb)
    d.line(P([A(p) for p in pts] + [A(pts[0])]),
           fill=blend(rim_rgb, body_rgb, rim[3]), width=max(1, int((1.0 + 1.4*t) * S)), joint="curve")

    size = DIGIT_SIZE
    f = ImageFont.truetype(FRICK, int(size * s * S))
    asc, desc = f.getmetrics()
    baseline = cy + (NUMBER_CENTER[1] + (asc - desc) / 2.0) * s
    posx = cx + (NUMBER_CENTER[0] - DIGIT_BOX / 2.0 + DIGIT_BOX / 2.0) * s
    digit_a = DIGIT_ALPHA_COOL + (DIGIT_ALPHA_HOT - DIGIT_ALPHA_COOL) * t
    d.text((posx * S, baseline * S), str(value), font=f,
           fill=col((rim[0], rim[1], rim[2], digit_a)), anchor="ms",
           stroke_width=max(1, int(round(2 + 2*t) * s * S * 0.5)), stroke_fill=DIGIT_OUTLINE)


def slot(x, y, w):
    d.rounded_rectangle([x*S, y*S, (x+w)*S, (y+w)*S], radius=8*S,
                        fill=SLOT_BG, outline=blend(SLOT_LINE, SLOT_BG, 0.45), width=S)


f_t = ImageFont.truetype(CJK, 24 * S)
f_s = ImageFont.truetype(CJK, 14 * S)
f_l = ImageFont.truetype(CJK, 15 * S)

d.text((28*S, 20*S), "NumberBlock 改版预览（1 → 9，越右越烫，大小不变）", font=f_t, fill=(242, 242, 245))
d.text((28*S, 54*S), "按 number_shard.gd 的同一套公式渲染 · 放在真实 64px 槽位里 · 非引擎实渲",
       font=f_s, fill=(150, 152, 162))
d.line(P([(28, 80), (W-28, 80)]), fill=(52, 54, 62), width=S)

random.seed(11)
d.text((28*S, 92*S), "buffer 槽位（64px）· 体色 / 描边 / 辉光 随值变化；尺寸固定", font=f_l, fill=(150, 152, 162))
for i, v in enumerate(range(1, 10)):
    x = 30 + i * 76
    slot(x, 118, 64)
    draw_shard(x + 32, 150, v, random.randint(0, 999))

d.text((28*S, 216*S), "operand 内（整块 ×0.63）· 分档在小尺寸下依然读得出", font=f_l, fill=(150, 152, 162))
for i, v in enumerate((1, 3, 5, 7, 9)):
    x = 30 + i * 52
    slot(x, 242, 40)
    draw_shard(x + 20, 262, v, random.randint(0, 999), k=0.63)

d.text((28*S, 320*S), "1-3 安静、贴近槽位底色；7-9 偏暖发亮并带辉光。数字本身始终是主要读取通道，分档只是补强。",
       font=f_s, fill=(150, 152, 162))
d.text((28*S, 344*S), "旧的纯橙方块 + 5px 纯黑边，以及可见性为 false 的 Shadow 节点已一并移除。",
       font=f_s, fill=(120, 122, 132))

img.resize((W, H), Image.LANCZOS).save(".mockups/nb_preview.png")
print("saved .mockups/nb_preview.png")


verify()
