{:ok, client} = FLHook.Client.start_link(
  host: System.get_env("FLHOST", "localhost"),
  password: System.fetch_env!("FLPASS"),
  event_mode: true
)


defmodule EventListener do
  def listen do
    receive do
      %FLHook.Event{type: type, dict: dict} ->
        IO.inspect(dict, label: type)
        listen()
    end
  end
end

IO.puts("Awaiting events...")

FLHook.subscribe(client)
EventListener.listen()

Process.sleep(:infinity)
