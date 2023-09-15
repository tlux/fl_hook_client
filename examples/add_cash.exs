{:ok, client} = FLHook.Client.start_link(
  host: System.get_env("FLHOST", "localhost"),
  password: System.fetch_env!("FLPASS"),
  event_mode: false
)

char = System.fetch_env!("CHAR")

{:ok, result} = FLHook.cmd(
  client,
  {"addcash", [char, String.to_integer(System.fetch_env!("CASH"))]}
)

new_cash =
  result
  |> FLHook.Result.one()
  |> FLHook.Dict.fetch!("cash", :integer)

IO.puts("New cash: #{new_cash}")
