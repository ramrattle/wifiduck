from pathlib import Path
from pkgutil import extend_path
import sys


SRC_DIR = Path(__file__).resolve().parents[1] / "src"

if SRC_DIR.exists():
    src_text = str(SRC_DIR)
    if src_text not in sys.path:
        sys.path.insert(0, src_text)

__path__ = extend_path(__path__, __name__)
