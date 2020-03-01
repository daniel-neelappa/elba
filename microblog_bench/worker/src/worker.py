import datetime
import json
import os
import random
import time

import thrift
import yaml

import wise_inbox
import wise_queue
import wise_sub


class ServiceClientFactory:
  def __init__(self):
    conf_filename = os.path.join(os.path.abspath(os.path.dirname(__file__)),
        "..", "conf", "services.yml")
    with open(conf_filename) as conf_file:
      self._conf = yaml.safe_load(conf_file)

  def get_inbox_client(self):
    server = random.choice(self._conf["inbox"])
    return wise_inbox.Client(server["hostname"], server["port"])

  def get_queue_client(self):
    server = random.choice(self._conf["queue"])
    return wise_queue.Client(server["hostname"], server["port"])

  def get_subscription_client(self):
    server = random.choice(self._conf["subscription"])
    return wise_sub.Client(server["hostname"], server["port"])


def main():
  cl_factory = ServiceClientFactory()
  while True:
    queue_cl = cl_factory.get_queue_client()
    try:
      # Try to get a post from the queue.
      queue_entry = queue_cl.dequeue(queue_name="post")
    except wise_queue.TEmptyQueueException:
      queue_cl.close()
      # Do not spin if no post is in the queue.
      time.sleep(1)
      continue
    post = json.loads(queue_entry.message)
    # Get the author's subscribers.
    subscription_cl = cl_factory.get_subscription_client()
    subscriptions = subscription_cl.get_subscribers_of_channel(
        channel_name=str(post["author_id"]))
    subscription_cl.close()
    # Push post to the inbox of its author's subscribers.
    inbox_cl = cl_factory.get_inbox_client()
    for subscription_entry in subscriptions:
      inbox_cl.push(inbox_name=str(subscription_entry.subscriber_id),
          message_text=str(post["post_id"]))
    queue_cl.close()
    inbox_cl.close()


if __name__ == "__main__":
  main()
