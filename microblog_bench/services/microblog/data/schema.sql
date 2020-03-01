DROP TABLE IF EXISTS Endorsements;
DROP TABLE IF EXISTS Posts;

CREATE TABLE Posts(
  id SERIAL PRIMARY KEY,
  author_id INTEGER NOT NULL,
  parent_id INTEGER,
  text VARCHAR(280) NOT NULL,
  created_at VARCHAR(64) NOT NULL,
  FOREIGN KEY(parent_id) REFERENCES Posts(id)
);

CREATE TABLE Endorsements(
  id SERIAL PRIMARY KEY,
  endorser_id INTEGER NOT NULL,
  post_id INTEGER NOT NULL,
  created_at VARCHAR(64) NOT NULL,
  FOREIGN KEY(post_id) REFERENCES Posts(id)
);
