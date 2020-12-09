defmodule FLHook.StubTCPAdapter do
  @behaviour FLHook.TCPAdapter

  alias FLHook.Codec

  @impl true
  def controlling_process(_socket, _pid) do
    :ok
  end

  @impl true
  def connect(_address, _port, _options, _timeout) do
    {:ok, make_ref()}
  end

  @impl true
  def close(_socket) do
    :ok
  end

  @impl true
  def recv(_socket, _length, _timeout) do
    Codec.encode(:unicode, "OK\r\n")
  end

  @impl true
  def send(_socket, _iodata) do
    :ok
  end
end
