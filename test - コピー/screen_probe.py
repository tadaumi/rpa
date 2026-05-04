import sys
import json
import hashlib
import math
import ctypes
from pathlib import Path

from PIL import ImageGrab, Image, ImageOps, ImageEnhance, ImageFilter, ImageDraw
import pytesseract
from pytesseract import Output

try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

cmd = sys.argv[1]

COPY_WORDS = ["コピー", "コビー", "コヒー", "コヒ", "コピ", "copy"]
DELETE_WORDS = ["削除", "さく除", "消去", "delete"]


def print_json(obj):
    print(json.dumps(obj, ensure_ascii=False))


def get_cursor_pos_windows():
    class POINT(ctypes.Structure):
        _fields_ = [("x", ctypes.c_long), ("y", ctypes.c_long)]

    pt = POINT()
    ok = ctypes.windll.user32.GetCursorPos(ctypes.byref(pt))
    if not ok:
        raise OSError("GetCursorPos failed")
    return {"x": int(pt.x), "y": int(pt.y)}


def ensure_parent_dir(path_str: str):
    Path(path_str).parent.mkdir(parents=True, exist_ok=True)


def load_image(image_path: str) -> Image.Image:
    return Image.open(image_path).convert("RGB")


def upscale_image(img: Image.Image, scale: int = 3) -> Image.Image:
    w, h = img.size
    return img.resize((max(1, w * scale), max(1, h * scale)), Image.Resampling.LANCZOS)


def preprocess_for_ui_text(img: Image.Image) -> Image.Image:
    img = upscale_image(img, scale=3)
    img = ImageOps.grayscale(img)
    img = img.filter(ImageFilter.SHARPEN)
    img = ImageEnhance.Contrast(img).enhance(2.2)
    img = ImageEnhance.Brightness(img).enhance(1.1)
    img = img.point(lambda p: 255 if p > 170 else 0)
    return img


def normalize_text(s: str) -> str:
    t = (s or "").strip().lower()
    t = t.replace("\u3000", " ").replace("\n", " ").replace("\r", " ")
    t = " ".join(t.split())
    return t


def classify_text(s: str) -> str:
    n = normalize_text(s)
    if not n:
        return "UNKNOWN"
    if any(w in n for w in COPY_WORDS):
        return "COPY"
    if any(w in n for w in DELETE_WORDS):
        return "DELETE"
    return "UNKNOWN"


def ocr_text_and_boxes(image_path: str, tesseract_cmd: str):
    pytesseract.pytesseract.tesseract_cmd = tesseract_cmd
    original = load_image(image_path)
    processed = preprocess_for_ui_text(original)
    config = "--oem 3 --psm 6"

    text = pytesseract.image_to_string(processed, lang="jpn+eng", config=config)
    data = pytesseract.image_to_data(processed, lang="jpn+eng", config=config, output_type=Output.DICT)

    words = []
    n = len(data.get("text", []))
    for i in range(n):
        raw = data["text"][i]
        txt = (raw or "").strip()
        if not txt:
            continue
        try:
            conf = float(data.get("conf", ["-1"])[i])
        except Exception:
            conf = -1.0
        left = int(data["left"][i])
        top = int(data["top"][i])
        width = int(data["width"][i])
        height = int(data["height"][i])
        if width <= 0 or height <= 0:
            continue
        words.append(
            {
                "text": txt,
                "normalized": normalize_text(txt),
                "kind": classify_text(txt),
                "left": left,
                "top": top,
                "width": width,
                "height": height,
                "right": left + width,
                "bottom": top + height,
                "cx": left + width / 2.0,
                "cy": top + height / 2.0,
                "conf": conf,
            }
        )

    return text, processed, original, words


def point_hit(words, px: float, py: float):
    hit = None
    nearest = None
    nearest_dist = None
    for w in words:
        inside = w["left"] <= px <= w["right"] and w["top"] <= py <= w["bottom"]
        dx = w["cx"] - px
        dy = w["cy"] - py
        dist = math.hypot(dx, dy)
        if inside:
            if hit is None or (w["kind"] != "UNKNOWN" and hit["kind"] == "UNKNOWN"):
                hit = w
        if nearest is None or dist < nearest_dist:
            nearest = w
            nearest_dist = dist
    return hit, nearest, nearest_dist


def build_debug_image(processed: Image.Image, words, px: float, py: float, hit, nearest, out_path: str):
    ensure_parent_dir(out_path)
    dbg = processed.convert("RGB")
    draw = ImageDraw.Draw(dbg)
    for w in words:
        box = [w["left"], w["top"], w["right"], w["bottom"]]
        color = (0, 128, 255)
        if hit is not None and w["text"] == hit["text"] and w["left"] == hit["left"] and w["top"] == hit["top"]:
            color = (0, 200, 0)
        elif nearest is not None and w["text"] == nearest["text"] and w["left"] == nearest["left"] and w["top"] == nearest["top"]:
            color = (255, 140, 0)
        draw.rectangle(box, outline=color, width=2)
    r = 6
    draw.ellipse((px - r, py - r, px + r, py + r), outline=(255, 0, 0), width=3)
    dbg.save(out_path)


def serialize_word(w):
    if w is None:
        return None
    return {
        "text": w["text"],
        "normalized": w["normalized"],
        "kind": w["kind"],
        "left": int(w["left"]),
        "top": int(w["top"]),
        "width": int(w["width"]),
        "height": int(w["height"]),
        "right": int(w["right"]),
        "bottom": int(w["bottom"]),
        "conf": float(w["conf"]),
    }


if cmd == "cursor":
    print_json(get_cursor_pos_windows())
elif cmd == "capture":
    left = int(sys.argv[2])
    top = int(sys.argv[3])
    width = int(sys.argv[4])
    height = int(sys.argv[5])
    out_path = sys.argv[6]
    ensure_parent_dir(out_path)
    img = ImageGrab.grab(bbox=(left, top, left + width, top + height))
    img.save(out_path)
    print_json({"saved": True, "path": out_path, "left": left, "top": top, "width": width, "height": height})
elif cmd == "capture_full":
    out_path = sys.argv[2]
    ensure_parent_dir(out_path)
    img = ImageGrab.grab()
    img.save(out_path)
    print_json({"saved": True, "path": out_path, "mode": "full"})
elif cmd == "ocr":
    image_path = sys.argv[2]
    text_path = sys.argv[3]
    tesseract_cmd = sys.argv[4]
    ensure_parent_dir(text_path)
    text, processed, original, words = ocr_text_and_boxes(image_path, tesseract_cmd)
    with open(text_path, "w", encoding="utf-8") as f:
        f.write(text)
    processed_path = str(Path(text_path).with_suffix(".processed.png"))
    ensure_parent_dir(processed_path)
    processed.save(processed_path)
    print_json({
        "text": text,
        "text_path": text_path,
        "processed_image_path": processed_path,
        "image_width": int(original.size[0]),
        "image_height": int(original.size[1]),
        "processed_width": int(processed.size[0]),
        "processed_height": int(processed.size[1]),
        "scale_x": float(processed.size[0]) / max(1, int(original.size[0])),
        "scale_y": float(processed.size[1]) / max(1, int(original.size[1])),
        "words": [serialize_word(w) for w in words],
    })
elif cmd == "ocr_hit":
    image_path = sys.argv[2]
    text_path = sys.argv[3]
    tesseract_cmd = sys.argv[4]
    capture_left = int(sys.argv[5])
    capture_top = int(sys.argv[6])
    capture_width = int(sys.argv[7])
    capture_height = int(sys.argv[8])
    point_x = int(sys.argv[9])
    point_y = int(sys.argv[10])
    ensure_parent_dir(text_path)
    text, processed, original, words = ocr_text_and_boxes(image_path, tesseract_cmd)
    with open(text_path, "w", encoding="utf-8") as f:
        f.write(text)
    processed_path = str(Path(text_path).with_suffix(".processed.png"))
    ensure_parent_dir(processed_path)
    processed.save(processed_path)
    scale_x = float(processed.size[0]) / max(1, int(capture_width))
    scale_y = float(processed.size[1]) / max(1, int(capture_height))
    point_original_x = float(point_x - capture_left)
    point_original_y = float(point_y - capture_top)
    point_processed_x = point_original_x * scale_x
    point_processed_y = point_original_y * scale_y
    hit, nearest, nearest_dist = point_hit(words, point_processed_x, point_processed_y)
    nearest_limit = max(24.0 * scale_y, 80.0)
    hit_source = "none"
    chosen = None
    if hit is not None:
        chosen = hit
        hit_source = "inside"
    elif nearest is not None and nearest_dist is not None and nearest_dist <= nearest_limit:
        chosen = nearest
        hit_source = "nearest"
    hit_kind = "UNKNOWN"
    hit_text = ""
    if chosen is not None:
        hit_kind = chosen["kind"]
        hit_text = chosen["text"]
    debug_path = str(Path(text_path).with_suffix(".hit.png"))
    build_debug_image(processed, words, point_processed_x, point_processed_y, hit, nearest, debug_path)
    print_json({
        "text": text,
        "text_path": text_path,
        "processed_image_path": processed_path,
        "hit_debug_image_path": debug_path,
        "image_width": int(original.size[0]),
        "image_height": int(original.size[1]),
        "processed_width": int(processed.size[0]),
        "processed_height": int(processed.size[1]),
        "scale_x": scale_x,
        "scale_y": scale_y,
        "capture_left": capture_left,
        "capture_top": capture_top,
        "capture_width": capture_width,
        "capture_height": capture_height,
        "point_screen": {"x": point_x, "y": point_y},
        "point_original": {"x": point_original_x, "y": point_original_y},
        "point_processed": {"x": point_processed_x, "y": point_processed_y},
        "hit_source": hit_source,
        "hit_kind": hit_kind,
        "hit_text": hit_text,
        "hit_word": serialize_word(chosen),
        "inside_word": serialize_word(hit),
        "nearest_word": serialize_word(nearest),
        "nearest_distance": None if nearest_dist is None else float(nearest_dist),
        "words": [serialize_word(w) for w in words],
    })
elif cmd == "compare":
    before_path = sys.argv[2]
    after_path = sys.argv[3]
    with open(before_path, "rb") as f:
        before_hash = hashlib.md5(f.read()).hexdigest()
    with open(after_path, "rb") as f:
        after_hash = hashlib.md5(f.read()).hexdigest()
    same = before_hash == after_hash
    print_json({"same": same, "before_hash": before_hash, "after_hash": after_hash})
else:
    print(f"unknown command: {cmd}", file=sys.stderr)
    sys.exit(1)
