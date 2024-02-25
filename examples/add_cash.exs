{:ok, client} =
  FLHook.Client.start_link(
    host: System.get_env("FLHOST", "localhost"),
    password: System.fetch_env!("FLPASS")
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
  |> FLHook.Result.one()
  |> FLHook.Dict.fetch!("cash", :integer)

IO.puts("New cash: #{new_cash}")
