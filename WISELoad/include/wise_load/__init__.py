import os, sys
original_sys_path = sys.path
sys.path.insert(0,
    os.path.join(os.path.abspath(os.path.dirname(__file__)), "..", "..", ".."))

from WISELoad.src.session import Session
from WISELoad.src.workload import Workload

sys.path = original_sys_path
