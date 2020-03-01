namespace py sub

struct TSubEntry {
  1: required i32 id;
  2: required i32 subscriber_id;
  3: required string channel_name;
  4: required string created_at;
}

exception TSubNotFoundException {
}

service TSubService {
  TSubEntry create_subscription (1:i32 subscriber_id,
      2:string channel_name);

  oneway void delete_subscription (1:i32 subscription_id);

  TSubEntry get_subscription (1:i32 subscriber_id,
      2:string channel_name)
      throws (1:TSubNotFoundException e);

  list<TSubEntry> get_subscribers_of_channel (1:string channel_name);

  list<TSubEntry> get_channels_subscribed_by (1:i32 subscriber_id);
}
