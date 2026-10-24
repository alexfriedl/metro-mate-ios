# Builds v2 of concepts D and A after docs/brand/icon-review.md, plus overview-v2.png and the mail confusion check.
# Run: DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib python build_v2.py  (needs cairosvg, pillow)
import os
from PIL import Image, ImageDraw
from build import OUT, BG, ORANGE, FG, SIZES, svg, render, squircle_mask, font, paste_rounded

OLD_ICON = os.path.join(OUT, "..", "..", "..", "Metronome", "Assets.xcassets", "AppIcon.appiconset", "metro-beat-1024.jpg")


def circle(x, y, r, c):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>'


# D v2: equal beat spacing, line 72, grey dots r60, beat r112 with ground ring r128, motif 16 px lower
def d_layers(line, beat, bg, rb=112, rr=128):
    dy = 16
    pts = [(192, 760 + dy), (352, 290 + dy), (512, 600 + dy), (672, 290 + dy), (832, 760 + dy)]
    poly = " ".join(f"{x},{y}" for x, y in pts)
    lines = f'<polyline points="{poly}" fill="none" stroke="{line}" stroke-width="72" stroke-linejoin="round" stroke-linecap="round"/>'
    lines += "".join(circle(x, y, 60, line) for i, (x, y) in enumerate(pts) if i != 1)
    bx, by = pts[1]
    return {"lines": lines, "ring": circle(bx, by, rr, bg), "beat": circle(bx, by, rb, beat)}


# A v2: 3x3 grid, pitch 232, grey r64, beat r112 top left
def a_layers(grey, beat):
    grid = "".join(circle(x, y, 64, grey) for y in (280, 512, 744) for x in (280, 512, 744) if (x, y) != (280, 280))
    return {"lines": grid, "beat": circle(280, 280, 112, beat)}


CONCEPTS = {
    "d-m-puls-v2": ("D v2  M aus Schlägen", lambda: d_layers(FG, ORANGE, BG), lambda: d_layers("#9A9A9A", "#FFFFFF", "#000000")),
    "a-raster-v2": ("A v2  Schlag im Raster", lambda: a_layers("#7A7A79", ORANGE), lambda: a_layers("#6A6A6A", "#FFFFFF")),
}


def build_concepts(concepts):
    renders = {}
    for key, (label, std, tint) in concepts.items():
        d = os.path.join(OUT, key)
        os.makedirs(d, exist_ok=True)
        ls, lt = std(), tint()
        full = "".join(ls.values())
        files = {
            f"icon-{key}.svg": svg(full, BG),
            f"icon-{key}-dark.svg": svg(full, BG),
            f"icon-{key}-tinted.svg": svg("".join(lt.values()), "#000000"),
            f"icon-{key}-layer-background.svg": svg("", BG),
        }
        for name, body in ls.items():
            files[f"icon-{key}-layer-{ {'lines': 'motif', 'ring': 'ring', 'beat': 'beat'}[name] }.svg"] = svg(body, None)
        for name, text in files.items():
            with open(os.path.join(d, name), "w") as f:
                f.write(text)
        imgs = {}
        for s in SIZES:
            imgs[s] = render(files[f"icon-{key}.svg"], s)
            imgs[s].save(os.path.join(d, f"icon-{key}-{s}.png"))
        imgs["tinted"] = render(files[f"icon-{key}-tinted.svg"], 1024)
        imgs["tinted"].save(os.path.join(d, f"icon-{key}-tinted-1024.png"))
        renders[key] = imgs
    return renders


def build():
    renders = build_concepts(CONCEPTS)
    overview(renders, CONCEPTS, "overview-v2.png")
    mail_check(renders["d-m-puls-v2"][1024])


def homescreen_block(img, dr, icon, x, y, w, bg, label, label_fill, f_small):
    dr.rectangle([x, y, x + w, y + 260], fill=bg)
    paste_rounded(img, icon, (x + 20, y + 20), 180)
    paste_rounded(img, icon, (x + 220, y + 20), 120)
    paste_rounded(img, icon, (x + 360, y + 20), 60)
    paste_rounded(img, icon, (x + 360, y + 100), 29)
    dr.text((x + 20, y + 222), label, fill=label_fill, font=f_small)


def overview(renders, concepts, out_name):
    col_w, pad = 560, 50
    W = pad + len(renders) * (col_w + pad)
    H = 1720
    img = Image.new("RGB", (W, H), "#2A2A29")
    dr = ImageDraw.Draw(img)
    f_label, f_small = font(32), font(20)
    for i, (key, imgs) in enumerate(renders.items()):
        x = pad + i * (col_w + pad)
        dr.text((x, 30), concepts[key][0], fill="#DDDDDD", font=f_label)
        img.paste(imgs[1024].resize((col_w, col_w), Image.LANCZOS), (x, 85))
        y = 85 + col_w + 30
        dr.rectangle([x, y, x + col_w, y + 230], fill=BG)
        cx = x + 20
        for s in [180, 120, 60, 29]:
            img.paste(imgs[s], (cx, y + 15))
            dr.text((cx, y + 20 + s), str(s), fill="#8A8A8A", font=f_small)
            cx += s + 30
        y2 = y + 260
        homescreen_block(img, dr, imgs[1024], x, y2, col_w, "#101418", "iOS-Rundung, dunkler Homescreen", "#8A8A8A", f_small)
        y3 = y2 + 280
        homescreen_block(img, dr, imgs[1024], x, y3, col_w, "#D9DEE6", "heller Homescreen", "#4A4A4A", f_small)
        y4 = y3 + 290
        paste_rounded(img, imgs["tinted"], (x, y4), 120)
        dr.text((x, y4 + 128), "Tinted", fill="#8A8A8A", font=f_small)
        img.paste(imgs[29].resize((145, 145), Image.NEAREST), (x + 180, y4))
        dr.text((x + 180, y4 + 150), "29 px, 5x gezoomt", fill="#8A8A8A", font=f_small)
        img.paste(imgs[60].resize((180, 180), Image.NEAREST), (x + 360, y4))
        dr.text((x + 360, y4 + 185), "60 px, 3x gezoomt", fill="#8A8A8A", font=f_small)
    img.save(os.path.join(OUT, out_name))


# neutral placeholder: flat colour field with a simple envelope, no real logos
def envelope_icon(fill, stroke, size=1024):
    body = (
        f'<rect x="232" y="322" width="560" height="380" rx="40" fill="none" stroke="{stroke}" stroke-width="56"/>'
        f'<polyline points="252,352 512,552 772,352" fill="none" stroke="{stroke}" stroke-width="56" stroke-linejoin="round" stroke-linecap="round"/>'
    )
    return render(svg(body, fill), size)


def plain_icon(fill, size=1024):
    return render(svg("", fill), size)


def mail_check(d_icon):
    old = Image.open(OLD_ICON).convert("RGB")
    mails = [
        ("Mail blau", envelope_icon("#1E7CF2", "#FFFFFF")),
        ("Mail weiß-rot", envelope_icon("#FFFFFF", "#D93025")),
        ("Mail rot", envelope_icon("#E5321D", "#FFFFFF")),
        ("Mail dunkel", envelope_icon("#121212", "#FFFFFF")),
    ]
    neutral = [plain_icon(c) for c in ("#3D8B5A", "#8A6BD1", "#F2B33D", "#5A6B7D")]
    f_small, f_label = font(20), font(30)
    icon, gap = 120, 44
    cols = 4
    pane_w = cols * icon + (cols - 1) * gap + 2 * 50
    W = 2 * pane_w + 3 * 40
    H = 900
    img = Image.new("RGB", (W, H), "#2A2A29")
    dr = ImageDraw.Draw(img)
    dr.text((40, 24), "Verwechslungsprüfung D v2 neben Mail-Platzhaltern (nur Farbflächen mit Umschlag)", fill="#DDDDDD", font=f_label)
    for p, (bg, txt) in enumerate([("#101418", "#B0B0B0"), ("#D9DEE6", "#3A3A3A")]):
        px = 40 + p * (pane_w + 40)
        py = 80
        dr.rectangle([px, py, px + pane_w, py + 780], fill=bg)
        rows = [
            [("Metro Mate D", d_icon)] + mails[:3],
            [mails[3]] + [("", n) for n in neutral[:3]],
            [("altes Icon", old), ("", neutral[3]), ("Metro Mate D", d_icon), mails[0]],
        ]
        for r, row in enumerate(rows):
            for c, (name, im) in enumerate(row):
                ix = px + 50 + c * (icon + gap)
                iy = py + 40 + r * (icon + 80)
                paste_rounded(img, im, (ix, iy), icon)
                if name:
                    dr.text((ix, iy + icon + 8), name, fill=txt, font=f_small)
        # small row at Settings size
        sy = py + 40 + 3 * (icon + 80)
        dr.text((px + 50, sy - 6), "29 px wie in den Einstellungen:", fill=txt, font=f_small)
        sx = px + 50
        for im in [d_icon, mails[0][1], mails[1][1], mails[2][1], mails[3][1], old]:
            paste_rounded(img, im, (sx, sy + 24), 29)
            sx += 29 + 16
    img.save(os.path.join(OUT, "mail-check-v2.png"))


if __name__ == "__main__":
    build()
