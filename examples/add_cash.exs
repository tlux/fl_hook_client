{:ok, client} =
  FLHook.connect(
    host: System.get_env("FLHOST", "windows-server"),
    password: System.get_env("FLPASS", "SuperSecret")
  )

user = System.fetch_env!("USER")

%{"cash" => new_cash} = FLHook.single!(client, "addcash #{user} 100")

IO.puts("New cash: #{new_cash}")
