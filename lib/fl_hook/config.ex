defmodule FLHook.Config do
  alias FLHook.Codec
  alias FLHook.ConfigError

  defstruct [
    :password,
    codec: :unicode,
    event_mode: false,
    host: "localhost",
    inet_adapter: :inet,
    port: 1920,
    subscribers: [],
    tcp_adapter: :gen_tcp
  ]

  @type t :: %__MODULE__{
          codec: Codec.codec(),
          event_mode: boolean,
          host: String.t(),
          inet_adapter: module,
          password: String.t(),
          port: non_neg_integer,
          subscribers: [GenServer.server()],
          tcp_adapter: module
        }

  @spec new(Keyword.t() | %{optional(atom) => any}) :: t
  def new(opts) do
    unless opts[:password] do
      raise ConfigError, "No password specified"
    end

    struct!(__MODULE__, opts)
  end
end
