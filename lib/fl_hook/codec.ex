defmodule FLHook.Codec do
  @moduledoc """
  A module that is responsible for decoding and encoding data streams from and
  to the FLHook socket.
  """

  alias FLHook.CodecError

  @typedoc """
  Type describing the supported codecs.
  """
  @type codec :: module

  @doc """
  Decodes binary data from the socket.
  """
  @callback decode(binary) :: {:ok, binary} | {:error, Exception.t()}

  @doc """
  Encodes binary data that will be sent to the socket.
  """
  @callback encode(binary) :: {:ok, binary} | {:error, Exception.t()}

  @doc """
  Decodes binary data from the socket using the specified codec.
  """
  @spec decode(codec, binary) :: {:ok, binary} | {:error, Exception.t()}
  def decode(codec, value) when is_binary(value) do
    case codec.decode(value) do
      {:ok, decoded} ->
        {:ok, decoded}

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
  @spec encode(codec, binary) :: {:ok, binary} | {:error, Exception.t()}
  def encode(codec, value) when is_binary(value) do
    case codec.encode(value) do
      {:ok, encoded} ->
        {:ok, encoded}

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
