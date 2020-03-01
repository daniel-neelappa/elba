import datetime
import time
import unittest

import wise_sub


SUB_HOST = "localhost"
SUB_PORT = 9094


class TestService(unittest.TestCase):
  def __init__(self, *args, **kwargs):
    super(TestService, self).__init__(*args, **kwargs)
    self._start_time = datetime.datetime.now()

  def setUp(self):
    self._client = wise_sub.Client(SUB_HOST, SUB_PORT)

  def tearDown(self):
    self._client.close()

  def testCreateSubscription(self):
    sub = self._client.create_subscription(1, "channel")
    self.assertEqual(sub.subscriber_id, 1)
    self.assertEqual(sub.channel_name, "channel")
    self.assertGreaterEqual(sub.created_at,
        self._start_time.strftime("%Y-%m-%d-%H-%M-%S"))
    self.assertLessEqual(sub.created_at,
        datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S"))

  def testDeleteSubscription(self):
    sub = self._client.create_subscription(2, "channel")
    self._client.delete_subscription(sub.id)
    # [NOTE] Sleep because |delete_subscription| is a oneway function.
    time.sleep(1)
    with self.assertRaises(wise_sub.TSubNotFoundException):
      self._client.get_subscription(2, "channel")

  def testGetSubscription(self):
    created_sub = self._client.create_subscription(1, "channelD")
    fetched_sub = self._client.get_subscription(1, "channelD")
    self.assertEqual(created_sub.id, fetched_sub.id)

  def testGetSubscribersOfChannel(self):
    self._client.create_subscription(1, "channelA")
    self._client.create_subscription(1, "channelB")
    self._client.create_subscription(1, "channelC")
    self._client.create_subscription(2, "channelA")
    self._client.create_subscription(2, "channelB")
    subs = self._client.get_subscribers_of_channel("channelA")
    self.assertIsInstance(subs, list)
    self.assertEqual(len(subs), 2)
    self.assertEqual(subs[0].channel_name, "channelA")

  def testGetChannelsSubscribedBy(self):
    self._client.create_subscription(3, "channelX")
    self._client.create_subscription(3, "channelY")
    self._client.create_subscription(3, "channelZ")
    subs = self._client.get_channels_subscribed_by(3)
    self.assertIsInstance(subs, list)
    self.assertEqual(len(subs), 3)
    self.assertEqual(subs[0].subscriber_id, 3)

  def testSubNotFoundException(self):
    with self.assertRaises(wise_sub.TSubNotFoundException):
      self._client.get_subscription(1, "channelZ")


if __name__ == "__main__":
  unittest.main()
