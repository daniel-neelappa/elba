namespace py auth

struct TAccount {
  1: required i32 id;
  2: required string username;
  3: required string first_name;
  4: required string last_name;
  5: required string created_at;
}

exception TInvalidCredentialsException {
}

service TAuthService {
  TAccount sign_up (1:string username, 2:string password, 3:string first_name,
      4:string last_name);

  TAccount sign_in (1:string username, 2:string password)
      throws (1:TInvalidCredentialsException e);
}
