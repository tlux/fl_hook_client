{:ok, client} =
  FLHook.connect(
    host: System.get_env("FLHOST", "windows-server"),
    password: System.get_env("FLPASS", "SuperSecret")
  )

IO.inspect(FLHook.single!(client, "serverinfo"))
