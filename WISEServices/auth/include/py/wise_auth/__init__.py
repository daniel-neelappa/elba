import os, sys
original_sys_path = sys.path
sys.path.insert(0,
    os.path.join(os.path.abspath(os.path.dirname(__file__)),
        "..", "..", "..", ".."))

from auth.src.py.gen_auth.auth.ttypes import TAccount, \
    TInvalidCredentialsException
from auth.src.py.client import Client

sys.path = original_sys_path
