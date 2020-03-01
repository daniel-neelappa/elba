import os, sys
original_sys_path = sys.path
sys.path.insert(0,
    os.path.join(os.path.abspath(os.path.dirname(__file__)),
        "..", "..", "..", ".."))

from microblog.src.py.gen_microblog.microblog.ttypes import TPost
from microblog.src.py.client import Client

sys.path = original_sys_path 
