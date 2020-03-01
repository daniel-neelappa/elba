import json
import os
import random

import flask
import flask_httpauth
import yaml

import wise_auth
import wise_inbox
import wise_microblog
import wise_queue
import wise_sub


class ServiceClientFactory:
  def __init__(self):
    conf_filename = os.path.join(os.path.abspath(os.path.dirname(__file__)),
        "..", "conf", "services.yml")
    with open(conf_filename) as conf_file:
      self._conf = yaml.safe_load(conf_file)

  def get_authentication_client(self):
    server = random.choice(self._conf["authentication"])
    return wise_auth.Client(server["hostname"], server["port"])

  def get_inbox_client(self):
    server = random.choice(self._conf["inbox"])
    return wise_inbox.Client(server["hostname"], server["port"])

  def get_microblog_client(self):
    server = random.choice(self._conf["microblog"])
    return wise_microblog.Client(server["hostname"], server["port"])

  def get_queue_client(self):
    server = random.choice(self._conf["queue"])
    return wise_queue.Client(server["hostname"], server["port"])

  def get_subscription_client(self):
    server = random.choice(self._conf["subscription"])
    return wise_sub.Client(server["hostname"], server["port"])


def setup_app():
  app = flask.Flask(__name__)
  app.url_map.strict_slashes = False
  return app


app = setup_app()
auth = flask_httpauth.HTTPBasicAuth()
cl_factory = ServiceClientFactory()


@auth.verify_password
def verify_password(username, password):
  authentication_cl = cl_factory.get_authentication_client()
  try:
    flask.g.account = authentication_cl.sign_in(username=username,
        password=password)
  except Exception:
    flask.g.account = None
  authentication_cl.close()
  return flask.g.account is not None


@app.route("/account", methods=["POST"])
def sign_up():
  username = flask.request.json["username"]
  password = flask.request.json["password"]
  first_name = flask.request.json["first_name"]
  last_name = flask.request.json["last_name"]
  authentication_cl = cl_factory.get_authentication_client()
  authentication_cl.sign_up(username=username, password=password,
      first_name=first_name, last_name=last_name)
  authentication_cl.close()
  return ""


@app.route("/post", methods=["POST"])
@auth.login_required
def create_post():
  text = flask.request.json["text"]
  parent_id = flask.request.json.get("parent_id", None)
  microblog_cl = cl_factory.get_microblog_client()
  post_id = microblog_cl.create_post(text=text, author_id=flask.g.account.id,
      parent_id=parent_id)
  microblog_cl.close()
  queue_cl = cl_factory.get_queue_client()
  queue_cl.enqueue(queue_name="post",
      message=json.dumps({"post_id": post_id, "author_id": flask.g.account.id}),
      expires_at="2099-01-01-00-00-00")
  queue_cl.close()
  return ""


@app.route("/endorsement/<post_id>", methods=["POST"])
@auth.login_required
def endorse_post(post_id):
  microblog_cl = cl_factory.get_microblog_client()
  microblog_cl.endorse_post(endorser_id=flask.g.account.id,
      post_id=int(post_id))
  microblog_cl.close()
  return ""


@app.route("/subscription/<user_id>", methods=["POST"])
@auth.login_required
def subscribe_to_user(user_id):
  subscription_cl = cl_factory.get_subscription_client()
  subscription_cl.create_subscription(subscriber_id=flask.g.account.id,
      channel_name=user_id)
  subscription_cl.close()
  return ""


@app.route("/inbox", methods=["GET"])
@auth.login_required
def inbox():
  n = int(flask.request.args.get("n", 16))
  offset = int(flask.request.args.get("offset", 0))
  inbox_cl = cl_factory.get_inbox_client()
  microblog_cl = cl_factory.get_microblog_client()
  posts = []
  for message in inbox_cl.fetch(inbox_name=("%s" % flask.g.account.id), n=n,
      offset=offset):
    post = microblog_cl.get_post(int(message.text))
    posts.append({
        "id": post.id,
        "text": post.text,
        "author_id": post.author_id,
        "n_endorsements": post.n_endorsements,
        "parent_id": post.parent_id
    })
  inbox_cl.close()
  microblog_cl.close()
  return flask.jsonify(posts)


@app.route("/post", methods=["GET"])
@auth.login_required
def recent_posts():
  n = int(flask.request.args.get("n", 10))
  offset = int(flask.request.args.get("offset", 0))
  microblog_cl = cl_factory.get_microblog_client()
  posts = [{
          "id": post.id,
          "text": post.text,
          "author_id": post.author_id,
          "n_endorsements": post.n_endorsements,
          "parent_id": post.parent_id
  } for post in microblog_cl.recent_posts(n=n, offset=offset)]
  microblog_cl.close()
  return flask.jsonify(posts)
