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

  @doc """
  Decodes binary data from the socket using the specified codec.
  """
  @spec decode(codec, binary) :: {:ok, String.t()} | {:error, CodecError.t()}
  def decode(:unicode, value) do
    {:ok, :unicode.characters_to_binary(value, {:utf16, :little}, :utf8)}
  end

  def decode(codec, value) do
    {:error,
     %CodecError{
       direction: :decode,
       codec: codec,
       value: value
     }}
  end

  @doc """
  Encodes strings that will be sent to the socket using the specified codec.
  """
  @spec encode(codec, String.t()) :: {:ok, binary} | {:error, CodecError.t()}
  def encode(:unicode, value) do
    {:ok, :unicode.characters_to_binary(value, :utf8, {:utf16, :little})}
  end

  def encode(codec, value) do
    {:error,
     %CodecError{
       direction: :encode,
       codec: codec,
       value: value
     }}
  end
end
