defmodule FLHook.TCPAdapter do
  @type socket :: term

  @callback controlling_process(socket, pid) :: :ok

  @callback connect(
              address :: :inet.socket_address() | :inet.hostname(),
              port :: :inet.port_number(),
              options :: [term],
              timeout
            ) :: {:ok, socket} | {:error, :timeout | :inet.posix()}

  @callback close(socket) :: :ok

  @callback recv(socket, length :: non_neg_integer, timeout) ::
              {:ok, term} | {:error, :closed | :inet.posix()}

  @callback send(socket, iodata) :: :ok | {:error, :closed | :inet.posix()}
end
