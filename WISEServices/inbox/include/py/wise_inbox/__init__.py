import os, sys
original_sys_path = sys.path
sys.path.insert(0,
    os.path.join(os.path.abspath(os.path.dirname(__file__)),
        "..", "..", "..", ".."))

from inbox.src.py.gen_inbox.inbox.ttypes import TMessage
from inbox.src.py.client import Client

sys.path = original_sys_path 
