import os, sys
original_sys_path = sys.path
sys.path.insert(0,
    os.path.join(os.path.abspath(os.path.dirname(__file__)),
        "..", "..", "..", ".."))

from queue_.src.py.gen_queue.queue.ttypes import TQueueEntry, \
    TEmptyQueueException
from queue_.src.py.client import Client

sys.path = original_sys_path
