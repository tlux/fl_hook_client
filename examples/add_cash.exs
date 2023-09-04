{:ok, client} = FLHook.Client.start_link(
  host: System.get_env("FLHOST", "localhost"),
  password: System.fetch_env!("FLPASS"),
  event_mode: false
)

{:ok, result} = FLHook.cmd(client, {"addcash", ["MyUsername", 10]})

new_cash =
  result
  |> FLHook.Result.one()
  |> FLHook.Dict.fetch!("cash", :integer)

IO.puts("New cash: #{new_cash}")
