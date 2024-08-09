defmodule FLHook.XMLTTest do
  use ExUnit.Case, async: true

  alias FLHook.XMLT

  describe "new/0" do
    test "build empty XMLT" do
      assert XMLT.new() == %XMLT{}
    end
  end

  describe "align/2" do
    test "add left node" do
      assert XMLT.to_string(XMLT.align(%XMLT{}, :left)) ==
               ~s(<JUST loc="left"/>)
    end

    test "add center node" do
      assert XMLT.to_string(XMLT.align(%XMLT{}, :center)) ==
               ~s(<JUST loc="center"/>)
    end

    test "add right node" do
      assert XMLT.to_string(XMLT.align(%XMLT{}, :right)) ==
               ~s(<JUST loc="right"/>)
    end
  end

  describe "format/2" do
    test "add format node" do
      expected = ~s(<TRA data="0xBDC83400" mask="-1"/>)

      assert XMLT.to_string(XMLT.format(%XMLT{}, {52, 200, 189})) ==
               expected

      assert XMLT.to_string(XMLT.format(%XMLT{}, "34C8BD")) == expected

      assert XMLT.to_string(XMLT.format(%XMLT{}, "#34C8BD")) ==
               expected
    end

    test "add format node after text node" do
      assert XMLT.new()
             |> XMLT.text("Hello")
             |> XMLT.format({52, 200, 189})
             |> XMLT.to_string() ==
               ~s(<TEXT>Hello</TEXT><TRA data="0xBDC83400" mask="-1"/>)
    end

    test "raise on invalid color" do
      assert_raise ArgumentError, "invalid RGB color", fn ->
        XMLT.format(%XMLT{}, {256, 0, 0})
      end

      assert_raise ArgumentError, fn ->
        XMLT.format(%XMLT{}, "#GGFF00")
      end

      assert_raise ArgumentError, fn ->
        XMLT.format(%XMLT{}, "#GF0")
      end
    end
  end

  describe "format/3" do
    @color {255, 255, 255}

    test "add format node" do
      assert XMLT.to_string(XMLT.format(%XMLT{}, @color, nil)) ==
               ~s(<TRA data="0xFFFFFF00" mask="-1"/>)

      assert XMLT.to_string(XMLT.format(%XMLT{}, @color, [])) ==
               ~s(<TRA data="0xFFFFFF00" mask="-1"/>)

      assert XMLT.to_string(XMLT.format(%XMLT{}, @color, :big)) ==
               ~s(<TRA data="0xFFFFFF08" mask="-1"/>)

      assert XMLT.to_string(XMLT.format(%XMLT{}, @color, [:big, :bold])) ==
               ~s(<TRA data="0xFFFFFF09" mask="-1"/>)

      assert XMLT.to_string(
               XMLT.format(%XMLT{}, @color, [:big, :bold, :italic])
             ) ==
               ~s(<TRA data="0xFFFFFF0B" mask="-1"/>)

      assert XMLT.to_string(XMLT.format(%XMLT{}, @color, [:smoother, :small])) ==
               ~s(<TRA data="0xFFFFFF90" mask="-1"/>)

      assert XMLT.to_string(XMLT.format(%XMLT{}, @color, [:small])) ==
               ~s(<TRA data="0xFFFFFF90" mask="-1"/>)
    end

    test "add format node after text node" do
      assert XMLT.new()
             |> XMLT.text("Hello")
             |> XMLT.format({52, 200, 189}, [:very_big, :underline])
             |> XMLT.to_string() ==
               ~s(<TEXT>Hello</TEXT><TRA data="0xBDC83424" mask="-1"/>)
    end

    test "raise on invalid format flag" do
      assert_raise ArgumentError, "invalid format flag (:little)", fn ->
        XMLT.format(%XMLT{}, {52, 200, 189}, :little)
      end

      assert_raise ArgumentError, "invalid format flag (:little)", fn ->
        XMLT.format(%XMLT{}, {52, 200, 189}, [:big, :little])
      end
    end
  end

  describe "paragraph/1" do
    test "add paragraph node" do
      assert XMLT.to_string(XMLT.paragraph(%XMLT{})) == "<PARA/>"
    end
  end

  describe "text/2" do
    @text "Zwölf Boxkämpfer jagen Viktor quer über den großen Sylter Deich"

    test "add text node" do
      assert XMLT.to_string(XMLT.text(%XMLT{}, @text)) ==
               "<TEXT>#{@text}</TEXT>"
    end

    test "add text node with number" do
      assert XMLT.to_string(XMLT.text(%XMLT{}, 1337)) ==
               "<TEXT>1337</TEXT>"
    end

    test "add text node with atom" do
      assert XMLT.to_string(XMLT.text(%XMLT{}, :works_with_atoms)) ==
               "<TEXT>works_with_atoms</TEXT>"
    end

    test "add text node with escaping" do
      assert XMLT.to_string(
               XMLT.text(%XMLT{}, "The <, & and > characters are escaped")
             ) ==
               "<TEXT>The &#60;, &#38; and &#62; characters are escaped</TEXT>"
    end

    test "add text node after format node" do
      assert XMLT.new()
             |> XMLT.format({52, 200, 189}, :big)
             |> XMLT.text(@text)
             |> XMLT.to_string() ==
               ~s(<TRA data="0xBDC83408" mask="-1"/><TEXT>#{@text}</TEXT>)
    end
  end

  describe "Kernel.to_string/1" do
    test "delegates to FLHook.XMLT" do
      xml_text =
        XMLT.new()
        |> XMLT.format({52, 200, 189}, :big)
        |> XMLT.text(@text)

      assert XMLT.to_string(xml_text) == to_string(xml_text)
    end
  end
end
