import csv
import numpy
import sys


PORT = sys.argv[1]
DIRS = [sys.argv[i] for i in range(2, len(sys.argv))]
INTERVAL_SIZE = 25000


class LogEntry:
  """A TCP/IP event log entry."""

  def __init__(self, event, ts, sock_fd):
    """Initialize a LogEntry.

    event -- [str] Name of the invoked syscall: 'connect', 'sendto', or 'recvfrom'.
    ts -- [int] Timestamp generated when the syscall was invoked.
    sock_fd -- [int] File descriptor of the socket used by the syscall.
    """
    self._event = event
    self._ts = ts
    self._sock_fd = sock_fd

  def __lt__(self, other):
    """Less than comparison operator.

    other -- [LogEntry] Another LogEntry being compared against this.
    """
    return self._ts < other._ts

  def event(self):
    """Return the name."""
    return self._event

  def ts(self):
    """Return the timestamp."""
    return self._ts

  def sock_fd(self):
    """Return the socket file descriptor."""
    return self._sock_fd

  def __repr__(self):
    """Return a string representation."""
    return "[{event} -- TS: {ts}; SOCK_FD: {sock_fd}]".format(
        event=self._event, ts=str(self._ts), sock_fd=str(self._sock_fd))


def build_requests(DIR):
  log_entries = []
  with open("%s/spec_connect.csv" % DIR) as connect_file:
    connect_reader = csv.DictReader(connect_file)
    for connect_row in connect_reader:
      if connect_row["PORT"] == PORT:
        log_entries.append(LogEntry(
            "connect", int(connect_row["TS"]), int(connect_row["SOCK_FD"])))
  with open("%s/spec_sendto.csv" % DIR) as sendto_file:
    sendto_reader = csv.DictReader(sendto_file)
    for sendto_row in sendto_reader:
      log_entries.append(LogEntry(
          "sendto", int(sendto_row["TS"]), int(sendto_row["SOCK_FD"])))
  with open("%s/spec_recvfrom.csv" % DIR) as recvfrom_file:
    recvfrom_reader = csv.DictReader(recvfrom_file)
    for recvfrom_row in recvfrom_reader:
      log_entries.append(LogEntry(
          "recvfrom", int(recvfrom_row["TS"]), int(recvfrom_row["SOCK_FD"])))
  log_entries.sort()
  requests = []
  for i in range(len(log_entries)):
    if log_entries[i].event() == "connect":
      request = [log_entries[i]]
      j = i + 1
      while j < len(log_entries) and (log_entries[j].event() != "connect" or
          log_entries[i].sock_fd() != log_entries[j].sock_fd()):
        if log_entries[i].sock_fd() == log_entries[j].sock_fd():
          request.append(log_entries[j])
        j += 1
      requests.append(request)
  return requests


def main():
  requests = []
  min_ts = None
  max_ts = None
  for DIR in DIRS:
    server_requests = build_requests(DIR)
    min_ts = min(min_ts, server_requests[0][0].ts()) \
        if min_ts else server_requests[0][0].ts()
    max_ts = max(max_ts, server_requests[-1][-1].ts()) \
        if max_ts else server_requests[-1][-1].ts()
    requests.extend(server_requests)
  ql = [0] * (int((max_ts - min_ts) / INTERVAL_SIZE) + 40 * 10)
  for request in requests:
    start_at_slot = (request[0].ts() - min_ts) // INTERVAL_SIZE
    finish_at_slot = (request[-1].ts() - min_ts) // INTERVAL_SIZE
    for slot in range(start_at_slot, finish_at_slot + 1):
      ql[slot] += 1
  with open("queue_length.data", 'w') as queue_length_file:
    for (slot_no, count) in enumerate(ql):
      queue_length_file.write("%s %s\n" % (slot_no * (INTERVAL_SIZE // 1000), count))
  # Print statistics.
  print("Number of intervals: %s" % len(ql))
  print("Min queue length: %s" % numpy.min(ql))
  print("Average queue length: %s" % numpy.average(ql))
  print("Median queue length: %s" % numpy.median(ql))
  print("Max queue length: %s" % numpy.max(ql))
  print("Std deviation of queue length: %s" % numpy.std(ql))


if __name__ == "__main__":
    main()
