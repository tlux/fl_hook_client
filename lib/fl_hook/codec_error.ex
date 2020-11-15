defmodule FLHook.CodecError do
  @moduledoc """
  An error indicating that decoding or encoding did not work.
  """

  defexception [:direction, :mode, :value, :reason]

  @type t :: %__MODULE__{
          direction: :decode | :encode,
          mode: FLHook.Codec.mode(),
          value: binary,
          reason: any
        }

  @impl true
  def message(error) do
    base_msg =
      "Unable to #{error.direction} value in #{inspect(error.mode)} mode"

    if error.reason do
      "#{base_msg} (#{error.reason})"
    else
      base_msg
    end
  end
end
