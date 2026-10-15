defmodule DevactionUISite.IndependenceTest do
  @moduledoc """
  The documentation site is a consumer of the library like any other, so it draws its tags, key caps and code
  blocks through the library too, and never reaches for another UI kit.
  """
  use ExUnit.Case, async: true

  @files Path.wildcard("lib/**/*.{ex,heex}")

  test "the site draws no tag of its own" do
    offenders =
      for file <- @files,
          Regex.match?(
            ~r/rounded-md border[^"]*"?[^>]*font-mono|font-mono[^>]*rounded-md border/s,
            File.read!(file)
          ),
          do: file

    assert offenders == [], "hand-made tags in: #{inspect(offenders)}; use <.tag>"
  end

  test "the site draws no key cap or code block of its own" do
    offenders =
      for file <- @files,
          source = File.read!(file),
          String.contains?(source, "<kbd") or String.contains?(source, "<pre"),
          do: file

    assert offenders == [], "hand-made <kbd>/<pre> in: #{inspect(offenders)}"
  end

  test "the site uses no other UI kit" do
    for file <- @files, word <- ~w(Fluxon daisyUI Heroicons) do
      refute File.read!(file) =~ word, "#{file} mentions #{word}"
    end
  end
end
