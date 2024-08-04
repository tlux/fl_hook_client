defmodule FLHook.CodecError do
  @moduledoc """
  An error indicating that decoding or encoding did not work.
  """

  alias FLHook.Codec

  @enforce_keys [:direction, :codec, :value]
  defexception [:direction, :codec, :value]

  @type t :: %__MODULE__{
          direction: :decode | :encode,
          codec: Codec.codec(),
          value: binary
        }

  @impl true
  def message(error) do
    "Unable to #{error.direction} value in #{inspect(error.codec)} mode"
  end
end
