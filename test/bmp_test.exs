defmodule BMPTest do
  use ExUnit.Case
  doctest BMP

  test "greets the world" do
    assert BMP.hello() == :world
  end
end
