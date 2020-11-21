defmodule FLHook.XMLText do
  require Bitwise

  alias FLHook.Utils

  defstruct chardata: ""

  @char_map %{
    "<" => "&#60;",
    ">" => "&#62;",
    "&" => "&#38;"
  }

  @flags %{
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

  @type color ::
          {red :: non_neg_integer, green :: non_neg_integer,
           blue :: non_neg_integer}
          | String.t()

  @type flag ::
          :bold
          | :italic
          | :underline
          | :big
          | :big_wide
          | :very_big
          | :smoothest
          | :smoother
          | :small

  @spec new() :: t
  def new do
    %__MODULE__{}
  end

  @spec new([
          {:format, color}
          | {:format, color, flag | [flag]}
          | {:text, String.t()}
          | String.t()
        ]) :: t
  def new(nodes) do
    Enum.reduce(nodes, %__MODULE__{}, fn
      {:format, color}, xml_text ->
        format(xml_text, color)

      {:format, color, flags}, xml_text ->
        format(xml_text, color, flags)

      {:text, text}, xml_text ->
        text(xml_text, text)

      text, xml_text when is_binary(text) ->
        text(xml_text, text)

      node, _xml_text ->
        raise ArgumentError, "invalid node: #{inspect(node)}"
    end)
  end

  @spec format(
          t,
          color,
          flag | [flag]
        ) :: t
  def format(%__MODULE__{} = xml_text, color, flags \\ []) do
    color = build_color(color)
    flags = build_flags(flags)
    node = ~s(<TRA data="0x#{color}#{flags}" mask="-1"/>)
    %{xml_text | chardata: [xml_text.chardata, node]}
  end

  defp build_flags(flags) do
    flags
    |> List.wrap()
    |> Enum.reduce(0, fn flag, value ->
      case Map.fetch(@flags, flag) do
        {:ok, flag_value} ->
          Bitwise.bor(value, flag_value)

        :error ->
          raise ArgumentError, "invalid format flag (#{inspect(flag)})"
      end
    end)
    |> to_hex()
  end

  @spec text(t, String.t()) :: t
  def text(%__MODULE__{} = xml_text, text) do
    text = Utils.map_chars(text, @char_map)
    node = ~s(<TEXT>#{text}</TEXT>)
    %{xml_text | chardata: [xml_text.chardata, node]}
  end

  defp build_color(color) do
    color
    |> normalize_color()
    |> Enum.map(&to_hex/1)
    |> Enum.join()
  end

  defguardp is_rgb_value(value) when value in 0..255

  defp normalize_color({red, green, blue})
       when is_rgb_value(red) and is_rgb_value(green) and is_rgb_value(blue) do
    [blue, green, red]
  end

  defp normalize_color(<<"#", code::binary-size(6)>>) do
    normalize_color(code)
  end

  defp normalize_color(<<"#", code::binary-size(3)>>) do
    normalize_color(code)
  end

  defp normalize_color(
         <<red::binary-size(2), green::binary-size(2), blue::binary-size(2)>>
       ) do
    Enum.map([blue, green, red], &String.to_integer(&1, 16))
  end

  defp normalize_color(
         <<red::binary-size(1), green::binary-size(1), blue::binary-size(1)>>
       ) do
    [blue, green, red]
    |> Enum.map(&String.duplicate(&1, 2))
    |> Enum.map(&String.to_integer(&1, 16))
  end

  defp normalize_color(_) do
    raise ArgumentError, "invalid RGB color"
  end

  defp to_hex(value) do
    value
    |> Integer.to_string(16)
    |> String.upcase()
    |> String.pad_leading(2, "0")
  end

  @spec to_string(t) :: String.t()
  def to_string(%__MODULE__{} = xml_text) do
    IO.chardata_to_string(xml_text.chardata)
  end

  defimpl String.Chars do
    defdelegate to_string(xml_text), to: FLHook.XMLText
  end
end
