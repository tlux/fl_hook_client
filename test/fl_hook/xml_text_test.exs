defmodule FLHook.XMLTextTest do
  use ExUnit.Case, async: true

  alias FLHook.XMLText

  describe "new/0" do
    test "build empty XMLText" do
      assert XMLText.new() == %XMLText{}
    end
  end

  describe "new/1" do
    test "compose new XMLText" do
      assert XMLText.to_string(
               XMLText.new([
                 {:format, {255, 127, 0}},
                 "Hello ",
                 {:format, {255, 255, 255}, :italic},
                 "World ",
                 1337,
                 {:format, "#FF0000", :small},
                 {:text, "!"},
                 {:align, :left},
                 {:align, :center},
                 :paragraph,
                 {:align, :right},
                 {:format, "00ff00", [:big, :bold]},
                 {:text, "!"}
               ])
             ) ==
               ~s(<TRA data="0x007FFF00" mask="-1"/>) <>
                 ~s(<TEXT>Hello </TEXT>) <>
                 ~s(<TRA data="0xFFFFFF02" mask="-1"/>) <>
                 ~s(<TEXT>World </TEXT>) <>
                 ~s(<TEXT>1337</TEXT>) <>
                 ~s(<TRA data="0x0000FF90" mask="-1"/>) <>
                 ~s(<TEXT>!</TEXT>) <>
                 ~s(<JUST loc="left"/>) <>
                 ~s(<JUST loc="center"/>) <>
                 ~s(<PARA/>) <>
                 ~s(<JUST loc="right"/>) <>
                 ~s(<TRA data="0x00FF0009" mask="-1"/>) <>
                 ~s(<TEXT>!</TEXT>)
    end
  end

  describe "align/2" do
    test "add left node" do
      assert XMLText.to_string(XMLText.align(%XMLText{}, :left)) ==
               ~s(<JUST loc="left"/>)
    end

    test "add center node" do
      assert XMLText.to_string(XMLText.align(%XMLText{}, :center)) ==
               ~s(<JUST loc="center"/>)
    end

    test "add right node" do
      assert XMLText.to_string(XMLText.align(%XMLText{}, :right)) ==
               ~s(<JUST loc="right"/>)
    end
  end

  describe "format/2" do
    test "add format node" do
      expected = ~s(<TRA data="0xBDC83400" mask="-1"/>)

      assert XMLText.to_string(XMLText.format(%XMLText{}, {52, 200, 189})) ==
               expected

      assert XMLText.to_string(XMLText.format(%XMLText{}, "34C8BD")) == expected

      assert XMLText.to_string(XMLText.format(%XMLText{}, "#34C8BD")) ==
               expected
    end

    test "add format node after text node" do
      assert XMLText.new()
             |> XMLText.text("Hello")
             |> XMLText.format({52, 200, 189})
             |> XMLText.to_string() ==
               ~s(<TEXT>Hello</TEXT><TRA data="0xBDC83400" mask="-1"/>)
    end

    test "raise on invalid color" do
      assert_raise ArgumentError, "invalid RGB color", fn ->
        XMLText.format(%XMLText{}, {256, 0, 0})
      end

      assert_raise ArgumentError, fn ->
        XMLText.format(%XMLText{}, "#GGFF00")
      end

      assert_raise ArgumentError, fn ->
        XMLText.format(%XMLText{}, "#GF0")
      end
    end
  end

  describe "format/3" do
    @color {255, 255, 255}

    test "add format node" do
      assert XMLText.to_string(XMLText.format(%XMLText{}, @color, nil)) ==
               ~s(<TRA data="0xFFFFFF00" mask="-1"/>)

      assert XMLText.to_string(XMLText.format(%XMLText{}, @color, [])) ==
               ~s(<TRA data="0xFFFFFF00" mask="-1"/>)

      assert XMLText.to_string(XMLText.format(%XMLText{}, @color, :big)) ==
               ~s(<TRA data="0xFFFFFF08" mask="-1"/>)

      assert XMLText.to_string(
               XMLText.format(%XMLText{}, @color, [:big, :bold])
             ) ==
               ~s(<TRA data="0xFFFFFF09" mask="-1"/>)

      assert XMLText.to_string(
               XMLText.format(%XMLText{}, @color, [:big, :bold, :italic])
             ) ==
               ~s(<TRA data="0xFFFFFF0B" mask="-1"/>)

      assert XMLText.to_string(
               XMLText.format(%XMLText{}, @color, [:smoother, :small])
             ) ==
               ~s(<TRA data="0xFFFFFF90" mask="-1"/>)

      assert XMLText.to_string(XMLText.format(%XMLText{}, @color, [:small])) ==
               ~s(<TRA data="0xFFFFFF90" mask="-1"/>)
    end

    test "add format node after text node" do
      assert XMLText.new()
             |> XMLText.text("Hello")
             |> XMLText.format({52, 200, 189}, [:very_big, :underline])
             |> XMLText.to_string() ==
               ~s(<TEXT>Hello</TEXT><TRA data="0xBDC83424" mask="-1"/>)
    end

    test "raise on invalid format flag" do
      assert_raise ArgumentError, "invalid format flag (:little)", fn ->
        XMLText.format(%XMLText{}, {52, 200, 189}, :little)
      end

      assert_raise ArgumentError, "invalid format flag (:little)", fn ->
        XMLText.format(%XMLText{}, {52, 200, 189}, [:big, :little])
      end
    end
  end

  describe "paragraph/1" do
    test "add paragraph node" do
      assert XMLText.to_string(XMLText.paragraph(%XMLText{})) == "<PARA/>"
    end
  end

  describe "text/2" do
    @text "Zwölf Boxkämpfer jagen Viktor quer über den großen Sylter Deich"

    test "add text node" do
      assert XMLText.to_string(XMLText.text(%XMLText{}, @text)) ==
               "<TEXT>#{@text}</TEXT>"
    end

    test "add text node with number" do
      assert XMLText.to_string(XMLText.text(%XMLText{}, 1337)) ==
               "<TEXT>1337</TEXT>"
    end

    test "add text node with atom" do
      assert XMLText.to_string(XMLText.text(%XMLText{}, :works_with_atoms)) ==
               "<TEXT>works_with_atoms</TEXT>"
    end

    test "add text node with escaping" do
      assert XMLText.to_string(
               XMLText.text(%XMLText{}, "The <, & and > characters are escaped")
             ) ==
               "<TEXT>The &#60;, &#38; and &#62; characters are escaped</TEXT>"
    end

    test "add text node after format node" do
      assert XMLText.new()
             |> XMLText.format({52, 200, 189}, :big)
             |> XMLText.text(@text)
             |> XMLText.to_string() ==
               ~s(<TRA data="0xBDC83408" mask="-1"/><TEXT>#{@text}</TEXT>)
    end
  end

  describe "Kernel.to_string/1" do
    test "delegates to FLHook.XMLText" do
      xml_text =
        XMLText.new()
        |> XMLText.format({52, 200, 189}, :big)
        |> XMLText.text(@text)

      assert XMLText.to_string(xml_text) == to_string(xml_text)
    end
  end
end
