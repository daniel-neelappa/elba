namespace py queue

struct TQueueEntry {
  1: required i32 id;
  2: required string queue_name;
  3: required string message;
  4: required string created_at;
  5: required string expires_at;
}

exception TEmptyQueueException {
}

service TQueueService {
  i32 enqueue (1:string queue_name, 2:string message, 3:string expires_at);

  TQueueEntry dequeue (1:string queue_name)
      throws (1:TEmptyQueueException e);
}
