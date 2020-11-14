defmodule FLHook.Coder do
  @spec decode(:unicode.encoding(), binary) :: binary
  defp decode(encoding, bin) do
    :unicode.characters_to_binary(bin, encoding, :utf8)
  end

  @spec encode(:unicode.encoding(), binary) :: binary
  defp encode(encoding, bin) do
    :unicode.characters_to_binary(bin, :utf8, encoding)
  end
end
