{:ok, client} =
  FLHook.Client.start_link(
    host: System.get_env("FLHOST", "windows-server"),
    password: System.get_env("FLPASS", "SuperSecret")
  )

new_cash =
  client
  |> FLHook.cmd!(
    {"addcash",
     [
       System.fetch_env!("CHAR"),
       String.to_integer(System.fetch_env!("CASH"))
     ]}
  )
  |> hd()
  |> FLHook.Dict.parse()
  |> Map.fetch!("cash")
  |> String.to_integer()

IO.puts("New cash: #{new_cash}")
