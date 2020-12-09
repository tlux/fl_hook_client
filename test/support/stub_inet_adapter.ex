defmodule FLHook.StubInetAdapter do
  @behaviour FLHook.InetAdapter

  @impl true
  def setopts(_socket, _opts) do
    :ok
  end
end
