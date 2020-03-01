import random
import time


class Delay:
  def sleep(self, speed_up_factor):
    raise NotImplementedError


class UniformDelay(Delay):
  def __init__(self, start, end):
    self._start = start
    self._end = end

  def sleep(self, speed_up_factor):
    time.sleep(random.uniform(start, end) / speed_up_factor)


class GaussianDelay(Delay):
  def __init__(self, mean, sd):
    self._mean = mean
    self._sd = sd

  def sleep(self, speed_up_factor):
    time.sleep(max(0, random.gauss(self._mean, self._sd)) / speed_up_factor)
