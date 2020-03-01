DROP TABLE IF EXISTS QueueEntries;
CREATE TABLE QueueEntries(
  id SERIAL PRIMARY KEY,
  queue_name VARCHAR(512) NOT NULL,
  message TEXT NOT NULL,
  created_at VARCHAR(64) NOT NULL,
  expires_at VARCHAR(64) NOT NULL
);
