defmodule FLHook.Config do
  @moduledoc """
  A struct containing configuration for a client.
  """

  alias FLHook.Codec

  @enforce_keys [:password]
  defstruct [
    :password,
    backoff_interval: 1000,
    codec: :unicode,
    connect_on_start: true,
    connect_timeout: 5000,
    event_mode: false,
    host: "localhost",
    inet_adapter: :inet,
    port: 1920,
    recv_timeout: 5000,
    send_timeout: 5000,
    tcp_adapter: :gen_tcp
  ]

  @type t :: %__MODULE__{
          codec: Codec.codec(),
          connect_on_start: boolean,
          event_mode: boolean,
          host: String.t(),
          inet_adapter: module,
          password: String.t(),
          port: :inet.port_number(),
          tcp_adapter: module
        }

  @doc false
  @spec new(Keyword.t() | %{optional(atom) => any}) :: t
  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end
end
