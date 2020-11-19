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

  @type flag :: 
    :bold |
    :italic |
    :underline |
    :big |
    :big_wide |
    :very_big |
    :smoothest |
    :smoother |
    :small

  @spec new() :: t
  def new do
    %__MODULE__{}
  end

  @spec format(t, String.t(), [flag]) :: t
  def format(%__MODULE__{} = xml_text, color, flags \\ []) do
    color = color_to_value(color) 
    format = flags_to_value(flags)
    add_node(xml_text, ~s(<TRA data="0x#{color}#{format}" mask="-1"/>))
  end

  @spec text(t, String.t()) :: t
  def text(%__MODULE__{} = xml_text, text) do
    text = Utils.map_chars(text, @char_map)
    add_node(xml_text, ~s(<TEXT>#{text}</TEXT>))
  end

  defp add_node(xml_text, str) do
    %{xml_text | chardata: [xml_text.chardata, str]}
  end

  defp color_to_value({red, green, blue}) do
    [blue, green, red]
    |> Enum.map(fn
      value when value in 0..255 -> to_hex(value)
      _ -> raise ArgumentError, "invalid RGB color"
    end)
    |> Enum.join()
  end

  defp color_to_value(<<"#", code::binary-size(6)>>), do: color_to_value(code)

  defp color_to_value(<<"#", code::binary-size(3)>>), do: color_to_value(code)

  defp color_to_value(
        <<red::binary-size(2), green::binary-size(2), blue::binary-size(2)>>
      ) do
    with {red, _} <- Integer.parse(red, 16),
         {green, _} <- Integer.parse(green, 16),
         {blue, _} <- Integer.parse(blue, 16) do
      color_to_value({red, green, blue})
    else
      _ -> raise ArgumentError, "invalid RGB color"     
    end
  end

  defp color_to_value(
        <<red::binary-size(1), green::binary-size(1), blue::binary-size(1)>>
      ) do
    red = String.duplicate(red, 2)
    green = String.duplicate(green, 2)
    blue = String.duplicate(blue, 2)
    color_to_value("#{red}#{green}#{blue}")
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
    defdelegate to_string(xml_text), to: FLHook.XMLText
  end
end
