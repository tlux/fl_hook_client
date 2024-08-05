import Config

config :logger, level: :warning

config :fl_hook_client, FLHook.TestClient,
  connect_on_start: false,
  inet_adapter: FLHook.MockInetAdapter,
  password: "Test1234",
  tcp_adapter: FLHook.MockTCPAdapter
