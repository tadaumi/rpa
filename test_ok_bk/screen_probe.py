import sys
import json
import hashlib
import ctypes
from PIL import ImageGrab, Image
import pytesseract

cmd = sys.argv[1]

def get_cursor_pos_windows():
    class POINT(ctypes.Structure):
        _fields_ = [("x", ctypes.c_long), ("y", ctypes.c_long)]
    pt = POINT()
    ok = ctypes.windll.user32.GetCursorPos(ctypes.byref(pt))
    if not ok:
        raise OSError("GetCursorPos failed")
    return {"x": int(pt.x), "y": int(pt.y)}

if cmd == "cursor":
    print(json.dumps(get_cursor_pos_windows(), ensure_ascii=False))
elif cmd == "capture":
    left = int(sys.argv[2]); top = int(sys.argv[3]); width = int(sys.argv[4]); height = int(sys.argv[5]); out_path = sys.argv[6]
    img = ImageGrab.grab(bbox=(left, top, left + width, top + height))
    img.save(out_path)
    print(json.dumps({"saved": True, "path": out_path, "left": left, "top": top, "width": width, "height": height}, ensure_ascii=False))
elif cmd == "capture_full":
    out_path = sys.argv[2]
    img = ImageGrab.grab()
    img.save(out_path)
    print(json.dumps({"saved": True, "path": out_path, "mode": "full"}, ensure_ascii=False))
elif cmd == "ocr":
    image_path = sys.argv[2]; text_path = sys.argv[3]; tesseract_cmd = sys.argv[4]
    pytesseract.pytesseract.tesseract_cmd = tesseract_cmd
    text = pytesseract.image_to_string(Image.open(image_path), lang="jpn+eng")
    with open(text_path, "w", encoding="utf-8") as f:
        f.write(text)
    print(json.dumps({"text": text, "text_path": text_path}, ensure_ascii=False))
elif cmd == "compare":
    before_path = sys.argv[2]; after_path = sys.argv[3]
    with open(before_path, "rb") as f:
        before_hash = hashlib.md5(f.read()).hexdigest()
    with open(after_path, "rb") as f:
        after_hash = hashlib.md5(f.read()).hexdigest()
    same = before_hash == after_hash
    print(json.dumps({"same": same, "before_hash": before_hash, "after_hash": after_hash}, ensure_ascii=False))
else:
    print(f"unknown command: {cmd}", file=sys.stderr)
    sys.exit(1)
