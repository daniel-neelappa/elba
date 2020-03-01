from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol

from .gen_microblog.microblog import TMicroblogService


class Client:
  def __init__(self, ip_address, port, timeout=10000):
    self._socket = TSocket.TSocket(ip_address, port)
    self._socket.setTimeout(timeout)
    self._transport = TTransport.TBufferedTransport(self._socket)
    self._protocol = TBinaryProtocol.TBinaryProtocol(self._transport)
    self._tclient = TMicroblogService.Client(self._protocol)
    self._transport.open()

  def __del__(self):
    self.close()

  def close(self):
    if self._transport.isOpen():
      self._transport.close()

  def create_post(self, text, author_id, parent_id=None):
    return self._tclient.create_post(text=text, author_id=author_id,
        parent_id=parent_id)

  def endorse_post(self, endorser_id, post_id):
    return self._tclient.endorse_post(endorser_id=endorser_id, post_id=post_id)

  def get_post(self, post_id):
    return self._tclient.get_post(post_id=post_id)

  def recent_posts(self, n, offset):
    return self._tclient.recent_posts(n=n, offset=offset)
