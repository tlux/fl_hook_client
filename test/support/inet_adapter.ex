defmodule FLHook.InetAdapter do
  @callback setopts(socket :: term, opts :: [:inet.socket_setopt()]) ::
              :ok | {:error, :inet.posix()}
end
