alias FLHook.XMLT

{:ok, client} =
  FLHook.connect(
    host: System.get_env("FLHOST", "windows-server"),
    password: System.get_env("FLPASS", "SuperSecret")
  )

text =
  XMLT.new()
  |> XMLT.format("#FF0000", [:bold, :italic])
  |> XMLT.text("Hello, World!")

FLHook.run!(client, "fmsgu #{text}")

IO.puts("Check your game for the text message!")
