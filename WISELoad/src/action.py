import random


class Action:
  def __init__(self, name, delay, transition_weights):
    self._name = name
    self._delay = delay
    self._transition_weights = transition_weights

  def name(self):
    return self._name

  def delay(self, speed_up_factor):
    self._delay.sleep(speed_up_factor)

  def transition(self):
    random_num = random.uniform(0, sum(self._transition_weights.values()))
    for transition, weight in self._transition_weights.items():
      if random_num < weight:
        return transition
      random_num -= weight
