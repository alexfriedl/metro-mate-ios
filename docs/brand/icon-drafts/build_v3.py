# Builds D v3 (smaller beat dot) and overview-v3.png comparing D v2 and D v3.
# Run: DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib python build_v3.py  (needs cairosvg, pillow)
import sys
from build import BG, ORANGE, FG
from build_v2 import d_layers, build_concepts, overview

RB = int(sys.argv[1]) if len(sys.argv) > 1 else 88

CONCEPTS = {
    "d-m-puls-v2": ("D v2  Schlag r 112", lambda: d_layers(FG, ORANGE, BG), lambda: d_layers("#9A9A9A", "#FFFFFF", "#000000")),
    "d-m-puls-v3": (f"D v3  Schlag r {RB}", lambda: d_layers(FG, ORANGE, BG, RB, RB + 16), lambda: d_layers("#9A9A9A", "#FFFFFF", "#000000", RB, RB + 16)),
}

if __name__ == "__main__":
    renders = build_concepts(CONCEPTS)
    overview(renders, CONCEPTS, "overview-v3.png")
