defmodule FLHook.ParamErrorTest do
  use ExUnit.Case, async: true

  alias FLHook.ParamError

  describe "message/1" do
    test "get error message" do
      assert Exception.message(%ParamError{
               key: "foo"
             }) == "invalid or missing param (foo)"
    end
  end
end
