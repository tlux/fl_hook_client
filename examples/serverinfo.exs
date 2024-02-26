{:ok, client} =
  FLHook.Client.start_link(
    host: System.get_env("FLHOST", "localhost"),
    password: System.fetch_env!("FLPASS")
  )

Process.sleep(500)

client
|> FLHook.cmd!("serverinfo")
|> FLHook.Result.one()
|> FLHook.Dict.to_map(:atom)
|> IO.inspect()
