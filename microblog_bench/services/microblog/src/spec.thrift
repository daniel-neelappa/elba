namespace py microblog

struct TPost {
  1: required i32 id;
  2: required string text;
  3: required i32 author_id;
  4: required i32 n_endorsements;
  5: optional i32 parent_id = -1;
}

service TMicroblogService {
  i32 create_post (1:string text, 2:i32 author_id, 3:i32 parent_id);

  oneway void endorse_post (1:i32 endorser_id, 2:i32 post_id);

  TPost get_post (1:i32 post_id);

  list<TPost> recent_posts (1:i32 n, 2:i32 offset);
}
