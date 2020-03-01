from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol

from .gen_auth.auth import TAuthService


class Client:
  def __init__(self, ip_address, port, timeout=10000):
    self._socket = TSocket.TSocket(ip_address, port)
    self._socket.setTimeout(timeout)
    self._transport = TTransport.TBufferedTransport(self._socket)
    self._protocol = TBinaryProtocol.TBinaryProtocol(self._transport)
    self._tclient = TAuthService.Client(self._protocol)
    self._transport.open()

  def __del__(self):
    self.close()

  def close(self):
    if self._transport.isOpen():
      self._transport.close()

  def sign_up(self, username, password, first_name, last_name):
    return self._tclient.sign_up(username=username, password=password,
        first_name=first_name, last_name=last_name)

  def sign_in(self, username, password):
    return self._tclient.sign_in(username=username, password=password)
