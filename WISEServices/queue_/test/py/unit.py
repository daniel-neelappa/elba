import datetime
import unittest

import wise_queue


QUEUE_HOST = "localhost"
QUEUE_PORT = 9093


class TestService(unittest.TestCase):
  def __init__(self, *args, **kwargs):
    super(TestService, self).__init__(*args, **kwargs)
    self._start_time = datetime.datetime.now()

  def setUp(self):
    self._client = wise_queue.Client(QUEUE_HOST, QUEUE_PORT)

  def tearDown(self):
    self._client.close()

  def testEnqueue(self):
    entry_id = self._client.enqueue("qa", "ping", "2099-01-01-00-00-00")
    self.assertIsInstance(entry_id, int)

  def testDequeue(self):
    self._client.enqueue("qb", "ping", "2099-01-01-00-00-00")
    self._client.enqueue("qb", "pong", "2099-01-01-00-00-00")
    entry = self._client.dequeue("qb")
    self.assertEqual(entry.queue_name, "qb")
    self.assertEqual(entry.message, "ping")
    self.assertGreaterEqual(entry.created_at,
        self._start_time.strftime("%Y-%m-%d-%H-%M-%S"))
    self.assertLessEqual(entry.created_at,
        datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S"))
    self.assertEqual(entry.expires_at, "2099-01-01-00-00-00")

  def testEmptyQueueException(self):
    with self.assertRaises(wise_queue.TEmptyQueueException):
      self._client.dequeue("qc")


if __name__ == "__main__":
  unittest.main()
