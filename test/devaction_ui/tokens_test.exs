defmodule DevactionUI.TokensTest do
  use ExUnit.Case, async: true

  @css Path.expand("../../assets/css/devaction_ui.css", __DIR__)
  @external_resource @css
  @tones [:risk, :warn, :ok, :info, :neutral, :indigo, :emerald]

  @tokens ~r/--([\w-]+): light-dark\((#[0-9A-Fa-f]{6}), (#[0-9A-Fa-f]{6})\);/
          |> Regex.scan(File.read!(@css))
          |> Map.new(fn [_all, name, light, dark] -> {name, %{light: light, dark: dark}} end)

  defp luminance("#" <> hex) do
    [r, g, b] =
      for <<channel::binary-size(2) <- hex>> do
        value = String.to_integer(channel, 16) / 255
        (value <= 0.03928 && value / 12.92) || :math.pow((value + 0.055) / 1.055, 2.4)
      end

    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  defp contrast(a, b) do
    [high, low] = Enum.sort([luminance(a), luminance(b)], :desc)
    (high + 0.05) / (low + 0.05)
  end

  defp ratio(text, background, scheme),
    do: contrast(@tokens[text][scheme], @tokens[background][scheme])

  for tone <- @tones, scheme <- [:light, :dark], kind <- ["text", "strong"] do
    test "#{tone} #{kind} reads on its surface in the #{scheme} theme" do
      assert ratio(
               "tag-#{unquote(tone)}-#{unquote(kind)}",
               "tag-#{unquote(tone)}-bg",
               unquote(scheme)
             ) >=
               4.5
    end
  end

  for text <- ["ink", "ink-2", "muted"], scheme <- [:light, :dark] do
    test "#{text} reads on the card in the #{scheme} theme" do
      assert ratio(unquote(text), "card", unquote(scheme)) >= 4.5
    end
  end

  test "every tone has the four tag tokens" do
    for tone <- @tones, part <- ["line", "bg", "text", "strong"] do
      assert Map.has_key?(@tokens, "tag-#{tone}-#{part}")
    end
  end
end
