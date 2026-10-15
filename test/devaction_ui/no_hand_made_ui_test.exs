defmodule DevactionUI.IndependenceTest do
  @moduledoc """
  The library stands alone: it reaches for no app, no Gettext backend and no other UI kit (Fluxon, daisyUI,
  Heroicons), so it can be published as it is.
  """
  use ExUnit.Case, async: true

  @forbidden ~w(DevactionIa Fluxon Gettext Heroicons daisyUI)

  test "the library depends on nothing outside Phoenix" do
    for file <- Path.wildcard("lib/**/*.ex"), word <- @forbidden do
      refute File.read!(file) =~ word, "#{file} mentions #{word}"
    end
  end

  test "the stylesheet and the hooks name no other UI kit" do
    for file <- ["assets/css/devaction_ui.css" | Path.wildcard("assets/js/devaction_ui/*.js")],
        word <- ~w(Fluxon fluxon) do
      refute File.read!(file) =~ word, "#{file} mentions #{word}"
    end
  end
end
