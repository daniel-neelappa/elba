from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol

from .gen_sub.sub import TSubService


class Client:
  def __init__(self, ip_address, port, timeout=10000):
    self._socket = TSocket.TSocket(ip_address, port)
    self._socket.setTimeout(timeout)
    self._transport = TTransport.TBufferedTransport(self._socket)
    self._protocol = TBinaryProtocol.TBinaryProtocol(self._transport)
    self._tclient = TSubService.Client(self._protocol)
    self._transport.open()

  def __del__(self):
    self.close()

  def close(self):
    if self._transport.isOpen():
      self._transport.close()

  def create_subscription(self, subscriber_id, channel_name):
    return self._tclient.create_subscription(subscriber_id=subscriber_id,
        channel_name=channel_name)

  def delete_subscription(self, subscription_id):
    return self._tclient.delete_subscription(subscription_id=subscription_id)

  def get_subscription(self, subscriber_id, channel_name):
    return self._tclient.get_subscription(subscriber_id=subscriber_id,
        channel_name=channel_name)

  def get_subscribers_of_channel(self, channel_name):
    return self._tclient.get_subscribers_of_channel(channel_name=channel_name)

  def get_channels_subscribed_by(self, subscriber_id):
    return self._tclient.get_channels_subscribed_by(subscriber_id=subscriber_id)
