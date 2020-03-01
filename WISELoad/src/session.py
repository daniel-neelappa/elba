from collections import OrderedDict
import datetime
import random
import string
import time

import yaml

from .action import Action
from .delay import UniformDelay, GaussianDelay


class Session:
  def __init__(self, config_filename):
    self._actions = OrderedDict()
    with open(config_filename) as config_file:
      config = yaml.safe_load(config_file)
    for action in config:
      name = action["action"]
      if action["delayDistribution"]["type"] == "uniform":
        delay = UniformDelay(action["delayDistribution"]["start"],
            action["delayDistribution"]["end"])
      elif action["delayDistribution"]["type"] == "gaussian":
        delay = GaussianDelay(action["delayDistribution"]["mean"],
            action["delayDistribution"]["sd"])
      transition_weights = OrderedDict()
      for (transition, weight) in action["transitionWeights"].items():
        transition_weights[transition] = weight
      self._actions[name] = Action(name, delay, transition_weights)

  def random_string(self, length):
    letters = string.ascii_lowercase + string.ascii_uppercase + string.digits
    return "".join(random.choice(letters) for i in range(length))

  def start(self, start_at, stop_at, burstiness):
    while datetime.datetime.now() < start_at:
      time.sleep(0.5)
    action = list(self._actions.values())[0]
    while datetime.datetime.now() < stop_at:
      now = datetime.datetime.now()
      speed_up_factor = 1.0
      for burst in burstiness:
        if now > burst["start_at"] and now < burst["stop_at"]:
          speed_up_factor = float(burst["speed_up_factor"])
      action.delay(speed_up_factor)
      getattr(self, action.name())()
      action = self._actions[action.transition()]
