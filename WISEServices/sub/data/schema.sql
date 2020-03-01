DROP TABLE IF EXISTS Subscriptions;
CREATE TABLE Subscriptions(
  id SERIAL PRIMARY KEY,
  subscriber_id INTEGER NOT NULL,
  channel_name VARCHAR(512) NOT NULL,
  created_at VARCHAR(64) NOT NULL
);
