defmodule FLHook.Codec do
  alias FLHook.CodecError

  @type codec :: :ascii | :unicode

  @spec decode(codec, binary) :: {:ok, binary} | {:error, CodecError.t()}
  def decode(:ascii, value) do
    {:ok, value}
  end

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

  @spec encode(codec, binary) :: {:ok, binary} | {:error, CodecError.t()}
  def encode(:ascii, value) do
    {:ok, value}
  end

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
