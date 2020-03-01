import datetime
import unittest

import wise_inbox


INBOX_HOST = "localhost"
INBOX_PORT = 9091


class TestService(unittest.TestCase):
  def __init__(self, *args, **kwargs):
    super(TestService, self).__init__(*args, **kwargs)
    self._start_time = datetime.datetime.now()

  def setUp(self):
    self._client = wise_inbox.Client(INBOX_HOST, INBOX_PORT)

  def tearDown(self):
    self._client.close()

  def testPush(self):
    self._client.push("foo", "ping")

  def testFetch(self):
    self._client.push("foo", "ping")
    self._client.push("foo", "pong")
    self._client.push("foo", "ping")
    self._client.push("foo", "pong")
    self._client.push("foo", "ping")
    self._client.push("foo", "pong")
    msgs = self._client.fetch("foo", 5, 0)
    self.assertIsInstance(msgs, list)
    self.assertEqual(len(msgs), 5)
    self.assertIn(msgs[0].text, ["ping", "pong"])
    self.assertGreaterEqual(msgs[0].created_at,
        self._start_time.strftime("%Y-%m-%d-%H-%M-%S"))
    self.assertLessEqual(msgs[0].created_at,
        datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S"))


if __name__ == "__main__":
  unittest.main()
