import os, sys
original_sys_path = sys.path
sys.path.insert(0,
    os.path.join(os.path.abspath(os.path.dirname(__file__)),
        "..", "..", "..", ".."))

from sub.src.py.gen_sub.sub.ttypes import TSubEntry, TSubNotFoundException
from sub.src.py.client import Client

sys.path = original_sys_path
