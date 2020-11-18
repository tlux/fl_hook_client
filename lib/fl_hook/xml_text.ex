defmodule FLHook.XMLText do
  require Bitwise

  alias FLHook.Utils

  defstruct chardata: []

  @char_map % {
    "<" => "&#60;" 
    ">" => "&#62;"
    "&" => "&#38;"
  }

  @format_flags %{
    bold: 1,
    italic: 2,
    underline: 4,
    big: 8,
    big_wide: 16,
    very_big: 32,
    smoothest: 64,
    smoother: 128,
    small: 144
  }

  @type t :: %__MODULE__{chardata: IO.chardata()}
  @type flag :: atom

  @spec add_node(t, String.t(), String.t(), [flag]) :: t
  def add_node(%__MODULE__{} = xml_text, text, color, flags \\ []) do
    text = Utils.map_chars(text, @char_map)
    color = color_to_value(color) 
    format = flags_to_value(flags)
    str = ~s(<TRA data="0x#{color}#{format}" mask="-1"/><TEXT>#{text}</TEXT>)
    %{xml_text | chardata: [xml_text.chardata, str]}
  end

  defp color_to_value({red, green, blue}) do
    [blue, green, red]
    |> Enum.map(&to_hex/1)
    |> Enum.join()
  end

  defp color_to_value(<<"#", code::binary-size(6)>>), do: color_to_value(code)

  defp color_to_value(<<"#", code::binary-size(3)>>), do: color_to_value(code)

  defp color_to_value(
        <<red::binary-size(2), green::binary-size(2), blue::binary-size(2)>>
      ) do
    "#{blue}#{green}#{red}"
  end

  defp color_to_value(
        <<red::binary-size(1), green::binary-size(1), blue::binary-size(1)>>
      ) do
    red = String.duplicate(red, 2)
    green = String.duplicate(green, 2)
    blue = String.duplicate(blue, 2)
    color_to_value(red, green, blue)
  end

  defp flags_to_value(flags) do
    flags
    |> Map.take(flags)
    |> Enum.reduce(0, fn {_flag, value}, acc ->
      Bitwise.bor(acc, value)
    end)
    |> to_hex()
  end

  defp to_hex(value) do
    value
    |> Integer.to_string(16)
    |> String.upcase()
  end

  @spec to_string(t) :: String.t()
  def to_string(%__MODULE__{} = xml_text) do
    IO.chardata_to_string(xml_text.chardata)
  end

  defimpl String.Chars do
    defdelegate to_string(xml_test), to: FLHook.XMLText
  end
end
