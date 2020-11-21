defmodule FLHook.CodecError do
  @moduledoc """
  An error indicating that decoding or encoding did not work.
  """

  defexception [:direction, :codec, :value, :reason]

  @type t :: %__MODULE__{
          direction: :decode | :encode,
          codec: FLHook.Codec.codec(),
          value: binary
        }

  @impl true
  def message(error) do
    "Unable to #{error.direction} value in #{inspect(error.codec)} mode"
  end
end
