namespace py inbox

struct TMessage {
  1: required i32 id;
  2: required string text;
  3: required string created_at;
}

service TInboxService {
  i32 push (1:string inbox_name, 2:string message_text);

  list<TMessage> fetch (1:string inbox_name, 2:i32 n, 3:i32 offset);
}
