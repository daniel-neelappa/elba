import datetime
import threading
import time


class SessionGroup:
  def __init__(self, session_cls, args, config_filename, no_concurrent_sessions,
        ramp_up_duration, ramp_down_duration, start_at, stop_at, burstiness):
    self._session_cls = session_cls
    self._args = args
    self._config_filename = config_filename
    self._no_concurrent_sessions = no_concurrent_sessions
    self._ramp_up_duration = ramp_up_duration
    self._ramp_down_duration = ramp_down_duration
    self._start_at = start_at
    self._stop_at = stop_at
    self._burstiness = burstiness

  def start(self):
    while datetime.datetime.now() < self._start_at:
      time.sleep(1)
    threads = [
        threading.Thread(
            target=self._session_cls(self._config_filename, *self._args).start,
            args=[self._start_at +
                i * self._ramp_up_duration / self._no_concurrent_sessions,
                self._stop_at - (self._no_concurrent_sessions - i) *
                self._ramp_down_duration / self._no_concurrent_sessions,
                self._burstiness])
        for i in range(self._no_concurrent_sessions)]
    for thread in threads:
      thread.start()
    for thread in threads:
      thread.join()
