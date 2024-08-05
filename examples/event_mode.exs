{:ok, client} =
  FLHook.Client.start_link(
    host: System.get_env("FLHOST", "windows-server"),
    password: System.get_env("FLPASS", "SuperSecret"),
    event_mode: true
  )

defmodule EventListener do
  def listen do
    receive do
      %FLHook.Event{} = event ->
        IO.inspect(event)
        listen()
    end
  end
end

IO.puts("Listening for events...")

FLHook.subscribe(client)
EventListener.listen()

Process.sleep(:infinity)
