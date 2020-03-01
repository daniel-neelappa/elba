import datetime
import threading

import yaml

from .session_group import SessionGroup


class Workload:
  def __init__(self, session_cls, config_filename, *args):
    with open(config_filename) as config_file:
      config = yaml.safe_load(config_file)
    now = datetime.datetime.now()
    self._session_groups = [
        SessionGroup(session_cls, args,
            config_filename=sg_spec["sessionConfig"],
            no_concurrent_sessions=sg_spec["noConcurrentSessions"],
            ramp_up_duration=datetime.timedelta(
                seconds=sg_spec["rampUpDuration"]),
            ramp_down_duration=datetime.timedelta(
                seconds=sg_spec["rampDownDuration"]),
            start_at=now + datetime.timedelta(seconds=sg_spec["startTime"]),
            stop_at=now + datetime.timedelta(seconds=sg_spec["endTime"]),
            burstiness=[{"speed_up_factor": burst_spec["speedUpFactor"],
                "start_at": now + \
                    datetime.timedelta(seconds=burst_spec["startTime"]),
                "stop_at": now + \
                    datetime.timedelta(seconds=burst_spec["endTime"])}
                for burst_spec in sg_spec.get("burstiness", [])])
        for sg_spec in config]

  def start(self):
    threads = [threading.Thread(target=sg.start) for sg in self._session_groups]
    for thread in threads:
      thread.start()
    for thread in threads:
      thread.join()
