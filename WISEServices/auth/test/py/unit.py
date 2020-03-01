import datetime
import unittest

import wise_auth


AUTH_HOST = "localhost"
AUTH_PORT = 9090


class TestService(unittest.TestCase):
  def __init__(self, *args, **kwargs):
    super(TestService, self).__init__(*args, **kwargs)
    self._start_time = datetime.datetime.now()

  def setUp(self):
    self._client = wise_auth.Client(AUTH_HOST, AUTH_PORT)

  def tearDown(self):
    self._client.close()

  def testSignUp(self):
    rrivellino = self._client.sign_up("rrivellino", "sccp1910", "Roberto",
        "Rivellino")
    self.assertEqual(rrivellino.username, "rrivellino")
    self.assertEqual(rrivellino.first_name, "Roberto")
    self.assertEqual(rrivellino.last_name, "Rivellino")
    self.assertGreaterEqual(rrivellino.created_at,
        self._start_time.strftime("%Y-%m-%d-%H-%M-%S"))
    self.assertLessEqual(rrivellino.created_at,
        datetime.datetime.now().strftime("%Y-%m-%d-%H-%M-%S"))

  def testSignIn(self):
    self._client.sign_up("jfneto", "sccp1910", "Jose F.", "Neto")
    jfneto = self._client.sign_in("jfneto", "sccp1910")
    self.assertEqual(jfneto.username, "jfneto")

  def testInvalidCredentialsException(self):
    self._client.sign_up("cassio12", "sccp1910", "Cassio", "Ramos")
    with self.assertRaises(wise_auth.TInvalidCredentialsException):
      self._client.sign_in("cassio12", "wrongpasswd")


if __name__ == "__main__":
  unittest.main()
