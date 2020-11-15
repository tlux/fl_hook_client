defmodule FLHook.Codec do
  @moduledoc false

  alias FLHook.CodecError

  # maybe also :ascii | :ascii_encrypted | :unicode_encrypted in the future
  @type mode :: :unicode

  @spec decode(mode, binary) :: {:ok, binary} | {:error, CodecError.t()}
  def decode(:unicode, value) do
    {:ok, :unicode.characters_to_binary(value, {:utf16, :little}, :utf8)}
  end

  def decode(mode, value) do
    {:error,
     %CodecError{
       direction: :decode,
       mode: mode,
       value: value,
       reason: :invalid_mode
     }}
  end

  @spec encode(mode, binary) :: {:ok, binary} | {:error, CodecError.t()}
  def encode(:unicode, value) do
    {:ok, :unicode.characters_to_binary(value, :utf8, {:utf16, :little})}
  end

  def encode(mode, value) do
    {:error,
     %CodecError{
       direction: :encode,
       mode: mode,
       value: value,
       reason: :invalid_mode
     }}
  end
end
