from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol

from .gen_inbox.inbox import TInboxService


class Client:
  def __init__(self, ip_address, port, timeout=10000):
    self._socket = TSocket.TSocket(ip_address, port)
    self._socket.setTimeout(timeout)
    self._transport = TTransport.TBufferedTransport(self._socket)
    self._protocol = TBinaryProtocol.TBinaryProtocol(self._transport)
    self._tclient = TInboxService.Client(self._protocol)
    self._transport.open()

  def __del__(self):
    self.close()

  def close(self):
    if self._transport.isOpen():
      self._transport.close()

  def push(self, inbox_name, message_text):
    return self._tclient.push(inbox_name=inbox_name, message_text=message_text)

  def fetch(self, inbox_name, n, offset):
    return self._tclient.fetch(inbox_name=inbox_name, n=n, offset=offset)
