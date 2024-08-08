defmodule FLHook.Config do
  @moduledoc """
  A struct containing configuration for a client.
  """

  alias FLHook.Codec

  @enforce_keys [:password]
  defstruct [
    :password,
    backoff_interval: 1000,
    codec: FLHook.Codecs.UTF16LE,
    connect_timeout: 5000,
    event_mode: false,
    host: "localhost",
    inet_adapter: :inet,
    open_on_start: true,
    port: 1920,
    recv_timeout: 5000,
    send_timeout: 5000,
    tcp_adapter: :gen_tcp
  ]

  @type t :: %__MODULE__{
          backoff_interval: non_neg_integer,
          codec: Codec.codec(),
          connect_timeout: timeout,
          event_mode: boolean,
          host: String.t(),
          inet_adapter: module,
          open_on_start: boolean,
          password: String.t(),
          port: :inet.port_number(),
          recv_timeout: timeout,
          send_timeout: timeout,
          tcp_adapter: module
        }

  @doc false
  @spec new(Keyword.t() | %{optional(atom) => any}) :: t
  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end
end
