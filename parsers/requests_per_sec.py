import csv
import numpy
import sys


PORT = sys.argv[1]
DIR = sys.argv[2]


def main():
  connect_calls = []
  with open("%s/spec_connect.csv" % DIR) as connect_file:
    connect_reader = csv.DictReader(connect_file)
    for connect_row in connect_reader:
      if connect_row["PORT"] == PORT:
        connect_calls.append(int(connect_row["TS"]))
  connect_calls.sort()
  requests_in_sec = [0] * \
      (int((connect_calls[-1] - connect_calls[0]) / 1000000.0) + 1)
  for cc in connect_calls:
    requests_in_sec[int((cc - connect_calls[0]) / 1000000.0)] += 1
  with open("requests_per_sec.data", 'w') as requests_per_sec_file:
    for (t, count) in enumerate(requests_in_sec):
      requests_per_sec_file.write("%s %s\n" % (t, count))


if __name__ == "__main__":
    main()
