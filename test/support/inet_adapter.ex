defmodule FLHook.InetAdapter do
  @callback setopts(socket :: term) :: :ok | {:error, :inet.posix()}
end
