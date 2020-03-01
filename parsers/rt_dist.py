import csv
import numpy
import sys


PORT = sys.argv[1]
DIR = sys.argv[2]


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


def main():
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
  rt_dist = [0] * (3 * 20)
  for request in requests:
    if request[-1].ts() - request[0].ts() > 3000000:
      continue
    rt_dist[int((request[-1].ts() - request[0].ts()) / 50000)] += 1
  with open("rt_dist.data", 'w') as rt_dist_file:
    for (t, count) in enumerate(rt_dist):
      rt_dist_file.write("%s %s\n" % (t * 50, count))


if __name__ == "__main__":
  main()
