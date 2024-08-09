require IEx

{:ok, client} =
  FLHook.Client.start_link(
    host: System.get_env("FLHOST", "windows-server"),
    password: System.get_env("FLPASS", "SuperSecret"),
    name: FL
  )

IEx.pry()

FLHook.Client.close(client)
