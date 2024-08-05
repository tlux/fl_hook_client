defmodule FLHook.Codecs.UTF16LE do
  @moduledoc """
  A module that is responsible for decoding and encoding data streams from and
  to the FLHook socket.
  """

  @behaviour FLHook.Codec

  @encoding {:utf16, :little}

  @impl true
  def decode(value) do
    case :unicode.characters_to_binary(value, @encoding, :utf8) do
      str when is_binary(str) -> {:ok, str}
      _ -> :error
    end
  end

  @impl true
  def encode(value) do
    case :unicode.characters_to_binary(value, :utf8, @encoding) do
      str when is_binary(str) -> {:ok, str}
      _ -> :error
    end
  end
end
