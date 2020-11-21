defmodule FLHook.CodecError do
  @moduledoc """
  An error indicating that decoding or encoding did not work.
  """

  defexception [:direction, :codec, :value, :reason]

  @type t :: %__MODULE__{
          direction: :decode | :encode,
          codec: FLHook.Codec.codec(),
          value: binary,
          reason: any
        }

  @impl true
  def message(error) do
    base_msg =
      "Unable to #{error.direction} value in #{inspect(error.codec)} mode"

    if error.reason do
      "#{base_msg} (#{error.reason})"
    else
      base_msg
    end
  end
end
