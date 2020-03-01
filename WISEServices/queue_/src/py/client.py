from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol

from .gen_queue.queue import TQueueService


class Client:
  def __init__(self, ip_address, port, timeout=10000):
    self._socket = TSocket.TSocket(ip_address, port)
    self._socket.setTimeout(timeout)
    self._transport = TTransport.TBufferedTransport(self._socket)
    self._protocol = TBinaryProtocol.TBinaryProtocol(self._transport)
    self._tclient = TQueueService.Client(self._protocol)
    self._transport.open()

  def __del__(self):
    self.close()

  def close(self):
    if self._transport.isOpen():
      self._transport.close()

  def enqueue(self, queue_name, message, expires_at):
    return self._tclient.enqueue(queue_name=queue_name, message=message,
        expires_at=expires_at)

  def dequeue(self, queue_name):
    return self._tclient.dequeue(queue_name=queue_name)
