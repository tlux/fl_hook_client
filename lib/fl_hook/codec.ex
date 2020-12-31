defmodule FLHook.Codec do
  @moduledoc """
  A module that is responsible for decoding and encoding data streams from and
  to the FLHook socket.
  """

  alias FLHook.CodecError

  @typedoc """
  Type describing the supported codecs.
  """
  @type codec :: :unicode

  @codecs %{unicode: {:utf16, :little}}

  @doc """
  Decodes binary data from the socket using the specified codec.
  """
  @spec decode(codec, binary) :: {:ok, String.t()} | {:error, CodecError.t()}
  def decode(codec, value) do
    with {:ok, src_encoding} <- Map.fetch(@codecs, codec),
         str when is_binary(str) <-
           :unicode.characters_to_binary(value, src_encoding, :utf8) do
      {:ok, str}
    else
      _ ->
        {:error,
         %CodecError{
           direction: :decode,
           codec: codec,
           value: value
         }}
    end
  end

  @doc """
  Encodes strings that will be sent to the socket using the specified codec.
  """
  @spec encode(codec, String.t()) :: {:ok, binary} | {:error, CodecError.t()}
  def encode(codec, value) do
    with {:ok, dest_encoding} <- Map.fetch(@codecs, codec),
         str when is_binary(str) <-
           :unicode.characters_to_binary(value, :utf8, dest_encoding) do
      {:ok, str}
    else
      _ ->
        {:error,
         %CodecError{
           direction: :encode,
           codec: codec,
           value: value
         }}
    end
  end
end
