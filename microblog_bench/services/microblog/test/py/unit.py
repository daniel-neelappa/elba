import datetime
import unittest

import wise_microblog


MICROBLOG_HOST = "localhost"
MICROBLOG_PORT = 9092


class TestService(unittest.TestCase):
  def __init__(self, *args, **kwargs):
    super(TestService, self).__init__(*args, **kwargs)
    self._start_time = datetime.datetime.now()

  def setUp(self):
    self._client = wise_microblog.Client(MICROBLOG_HOST, MICROBLOG_PORT)

  def tearDown(self):
    self._client.close()

  def testAll(self):
    # Create and endorse a post.
    ping_post_id = self._client.create_post("ping", 1)
    pong_post_id = self._client.create_post("pong", 1)
    self._client.endorse_post(2, ping_post_id)
    # Get the ping post.
    ping_post = self._client.get_post(ping_post_id)
    self.assertEqual(ping_post.text, "ping")
    self.assertEqual(ping_post.author_id, 1)
    self.assertEqual(ping_post.n_endorsements, 1)
    # Get the pong post.
    pong_post = self._client.get_post(pong_post_id)
    self.assertEqual(pong_post.text, "pong")
    self.assertEqual(pong_post.author_id, 1)
    self.assertEqual(pong_post.n_endorsements, 0)
    # [TODO] Get the recent posts.


if __name__ == "__main__":
  unittest.main()
