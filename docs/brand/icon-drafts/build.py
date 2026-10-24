# Builds all Metro Mate icon drafts (SVG + PNG + boards + overview).
# Run: DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib python build.py  (needs cairosvg, pillow)
import io
import os
import cairosvg
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.dirname(os.path.abspath(__file__))
BG = "#1C1C1B"
ORANGE = "#F54206"
FG = "#DDDDDD"
TILE = "#303030"
SIZES = [1024, 180, 120, 60, 29]


# #DDDDDD at given opacity over #1C1C1B, precomputed as solid colour
def dim(a):
    r = round(0x1C + a * (0xDD - 0x1C))
    b = round(0x1B + a * (0xDD - 0x1B))
    return f"#{r:02X}{r:02X}{b:02X}"


# tinted palette: black ground, greys, beat is the brightest value
TINT = {"bg": "#000000", "beat": "#FFFFFF", "fg": "#B4B4B4", "d70": "#8C8C8C", "d60": "#7A7A7A", "d50": "#6A6A6A", "d35": "#505050", "tile": "#383838"}
STD = {"bg": BG, "beat": ORANGE, "fg": FG, "d70": dim(0.7), "d60": dim(0.6), "d50": dim(0.5), "d35": dim(0.35), "tile": TILE}


def circle(x, y, r, c):
    return f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="{c}"/>'


# A: 4x4 dot grid, beat dot on count one, double diameter
def motif_a(p):
    pitch, r, rb = 196, 52, 96
    start = 512 - 1.5 * pitch
    out = []
    for row in range(4):
        for col in range(4):
            x, y = start + col * pitch, start + row * pitch
            if (row, col) == (0, 0):
                continue
            out.append(circle(x, y, r, p["d60"]))
    out.append(circle(start, start, rb, p["beat"]))
    return "".join(out)


# B: three dotted wave rows in perspective, centre jumps, beat dot on the peak
def motif_b(p):
    rows = [
        # y, half width, amplitude, line width, dot r, colour
        (310, 230, 70, 34, 30, p["d35"]),
        (510, 300, 130, 38, 36, p["d50"]),
        (770, 350, 200, 44, 44, p["d70"]),
    ]
    out = []
    peak = None
    for y, hw, amp, lw, dr, c in rows:
        xs = [512 - hw, 512 - hw * 0.45, 512, 512 + hw * 0.45, 512 + hw]
        ys = [y, y, y - amp, y, y]
        pts = " ".join(f"{x:.1f},{yy:.1f}" for x, yy in zip(xs, ys))
        out.append(f'<polyline points="{pts}" fill="none" stroke="{c}" stroke-width="{lw}" stroke-linejoin="round" stroke-linecap="round"/>')
        for i, (x, yy) in enumerate(zip(xs, ys)):
            if i == 2 and c == rows[-1][5]:
                peak = (x, yy)
                continue
            out.append(circle(x, yy, dr, c))
    out.append(circle(peak[0], peak[1], 78, p["beat"]))
    return "".join(out)


# C: four beat tiles as 2x2, the third count lights up like in the app
def motif_c(p):
    s, gap, rad = 330, 64, 48
    x0 = 512 - s - gap / 2
    out = []
    for row in range(2):
        for col in range(2):
            x, y = x0 + col * (s + gap), x0 + row * (s + gap)
            c = p["beat"] if (row, col) == (1, 0) else p["tile"]
            out.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{s}" height="{s}" rx="{rad}" fill="{c}"/>')
    return "".join(out)


# D: an M drawn as pulse zigzag through five beats, left peak is the beat
def motif_d(p):
    pts = [(222, 760), (342, 290), (512, 600), (682, 290), (802, 760)]
    poly = " ".join(f"{x},{y}" for x, y in pts)
    out = [f'<polyline points="{poly}" fill="none" stroke="{p["fg"]}" stroke-width="64" stroke-linejoin="round" stroke-linecap="round"/>']
    for i, (x, y) in enumerate(pts):
        if i == 1:
            continue
        out.append(circle(x, y, 62, p["fg"]))
    out.append(circle(pts[1][0], pts[1][1], 104, p["beat"]))
    return "".join(out)


CONCEPTS = {
    "a-raster": ("A  Schlag im Raster", motif_a),
    "b-welle": ("B  Welle springt", motif_b),
    "c-kacheln": ("C  Zählzeit-Kacheln", motif_c),
    "d-m-puls": ("D  M aus Schlägen", motif_d),
}


def svg(body, bg):
    rect = f'<rect width="1024" height="1024" fill="{bg}"/>' if bg else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">{rect}{body}</svg>\n'


def render(svg_text, size):
    png = cairosvg.svg2png(bytestring=svg_text.encode(), output_width=size, output_height=size)
    return Image.open(io.BytesIO(png)).convert("RGB")


# superellipse approximation of the iOS continuous corner mask
def squircle_mask(size, n=5.0):
    big = size * 4
    m = Image.new("L", (big, big), 0)
    pts = []
    import math
    for i in range(720):
        t = 2 * math.pi * i / 720
        c, s = math.cos(t), math.sin(t)
        x = abs(c) ** (2 / n) * (1 if c >= 0 else -1)
        y = abs(s) ** (2 / n) * (1 if s >= 0 else -1)
        pts.append(((x + 1) * big / 2, (y + 1) * big / 2))
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def font(sz):
    try:
        return ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", sz)
    except OSError:
        return ImageFont.load_default()


def paste_rounded(canvas, img, xy, size):
    canvas.paste(img.resize((size, size), Image.LANCZOS), xy, squircle_mask(size))


def build():
    renders = {}
    for key, (label, fn) in CONCEPTS.items():
        d = os.path.join(OUT, key)
        os.makedirs(d, exist_ok=True)
        files = {
            f"icon-{key}.svg": svg(fn(STD), BG),
            f"icon-{key}-dark.svg": svg(fn(STD), BG),
            f"icon-{key}-tinted.svg": svg(fn(TINT), TINT["bg"]),
            f"icon-{key}-layer-background.svg": svg("", BG),
            f"icon-{key}-layer-motif.svg": svg(fn(STD), None),
        }
        for name, text in files.items():
            with open(os.path.join(d, name), "w") as f:
                f.write(text)
        imgs = {}
        for s in SIZES:
            im = render(files[f"icon-{key}.svg"], s)
            im.save(os.path.join(d, f"icon-{key}-{s}.png"))
            imgs[s] = im
        render(files[f"icon-{key}-tinted.svg"], 1024).save(os.path.join(d, f"icon-{key}-tinted-1024.png"))
        imgs["tinted"] = render(files[f"icon-{key}-tinted.svg"], 1024)
        renders[key] = imgs
    overview(renders)


def overview(renders):
    col_w, pad = 440, 40
    W = pad + len(renders) * (col_w + pad)
    H = 1500
    img = Image.new("RGB", (W, H), "#2A2A29")
    dr = ImageDraw.Draw(img)
    f_label, f_small = font(30), font(20)
    for i, (key, imgs) in enumerate(renders.items()):
        x = pad + i * (col_w + pad)
        dr.text((x, 30), CONCEPTS[key][0], fill="#DDDDDD", font=f_label)
        img.paste(imgs[1024].resize((col_w, col_w), Image.LANCZOS), (x, 80))
        # small sizes at true pixel size on #1C1C1B
        y = 80 + col_w + 30
        dr.rectangle([x, y, x + col_w, y + 210], fill=BG)
        cx = x + 15
        for s in [180, 120, 60, 29]:
            img.paste(imgs[s], (cx, y + 15))
            dr.text((cx, y + 15 + s + 4), f"{s}", fill="#8A8A8A", font=f_small)
            cx += s + 12 if s > 29 else 0
        # dark homescreen with squircle mask
        y2 = y + 240
        dr.rectangle([x, y2, x + col_w, y2 + 260], fill="#101418")
        paste_rounded(img, imgs[1024], (x + 20, y2 + 20), 180)
        paste_rounded(img, imgs[1024], (x + 220, y2 + 20), 120)
        paste_rounded(img, imgs[1024], (x + 360, y2 + 20), 60)
        paste_rounded(img, imgs[1024], (x + 360, y2 + 100), 29)
        dr.text((x + 20, y2 + 220), "iOS-Rundung, dunkler Homescreen", fill="#8A8A8A", font=f_small)
        # light homescreen
        y3 = y2 + 280
        dr.rectangle([x, y3, x + col_w, y3 + 260], fill="#D9DEE6")
        paste_rounded(img, imgs[1024], (x + 20, y3 + 20), 180)
        paste_rounded(img, imgs[1024], (x + 220, y3 + 20), 120)
        paste_rounded(img, imgs[1024], (x + 360, y3 + 20), 60)
        paste_rounded(img, imgs[1024], (x + 360, y3 + 100), 29)
        dr.text((x + 20, y3 + 220), "heller Homescreen", fill="#4A4A4A", font=f_small)
        # tinted
        y4 = y3 + 280
        paste_rounded(img, imgs["tinted"], (x + 20, y4), 120)
        dr.text((x + 160, y4 + 50), "Tinted", fill="#8A8A8A", font=f_small)
        # zoomed 29 px to judge pixels
        img.paste(imgs[29].resize((116, 116), Image.NEAREST), (x + 300, y4))
        dr.text((x + 300, y4 + 120), "29 px, 4x gezoomt", fill="#8A8A8A", font=f_small)
    img.save(os.path.join(OUT, "overview.png"))


if __name__ == "__main__":
    build()
