{:ok, client} =
  FLHook.Client.start_link(
    host: System.get_env("FLHOST", "windows-server"),
    password: System.get_env("FLPASS", "SuperSecret")
  )

Process.sleep(500)

client
|> FLHook.cmd!("serverinfo")
|> hd()
|> FLHook.Dict.parse()
|> FLHook.Dict.coerce("serverload", :float)
|> FLHook.Dict.coerce("npcspawn", :boolean)
|> FLHook.Dict.coerce("uptime", :duration)
|> IO.inspect()
