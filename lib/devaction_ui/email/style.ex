defmodule DevactionUI.Email.Style do
  @moduledoc false

  @sans "Geist, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"
  @mono "Geist Mono, ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"

  @palette %{
    page: "#F4F4F5",
    card: "#FFFFFF",
    ink: "#18181B",
    muted: "#52525B",
    soft: "#71717A",
    line: "#E4E4E7",
    rule: "#EFEFF1",
    panel: "#F4F4F5",
    outline: "#D4D4D8",
    on_ink: "#FFFFFF"
  }

  @tones %{
    risk: %{line: "#FBCFCF", bg: "#FEF2F2", ink: "#B91C1C"},
    warn: %{line: "#F5DFA8", bg: "#FEF9EC", ink: "#854D0E"},
    ok: %{line: "#BBF7D0", bg: "#F0FDF4", ink: "#15803D"},
    info: %{line: "#C7D7FE", bg: "#EFF4FF", ink: "#1E40AF"},
    neutral: %{line: "#E4E4E7", bg: "#F4F4F5", ink: "#3F3F46"},
    highlight: %{line: "#F5DFA8", bg: "#FFFDF6", ink: "#854D0E"},
    person: %{line: "#EEF2FF", bg: "#EEF2FF", ink: "#3730A3"}
  }

  @type_scale %{
    body: "font-size: 16px; line-height: 1.6",
    compact: "font-size: 15px; line-height: 1.6",
    small: "font-size: 13px; line-height: 1.55"
  }

  @dark_rules [
    {".em-body", "background: #101016 !important"},
    {".em-card", "background: #1A1A22 !important; border-color: #2C2C38 !important"},
    {".em-ink", "color: #EDEDF2 !important"},
    {".em-muted", "color: #B4B4C4 !important"},
    {".em-soft", "color: #9B9BAE !important"},
    {".em-line", "background: #2C2C38 !important"},
    {".em-line-b", "border-color: #2C2C38 !important"},
    {".em-panel", "background: #20202A !important"},
    {".em-btn-primary", "background: #EDEDF2 !important; border-color: #EDEDF2 !important"},
    {".em-btn-primary a", "color: #15151C !important"},
    {".em-btn-secondary", "background: #20202A !important; border-color: #383846 !important"},
    {".em-btn-secondary a", "color: #EDEDF2 !important"},
    {".em-step-on", "background: #EDEDF2 !important; color: #15151C !important"}
  ]

  @base_css "body{margin:0;padding:0;-webkit-text-size-adjust:100%}a{text-decoration:none}@media (max-width:620px){.em-pad{padding:28px 22px !important}.em-outer{padding:20px 10px !important}}:root{color-scheme:light dark;supported-color-schemes:light dark}"

  def sans, do: @sans

  def mono, do: @mono

  def color(name), do: Map.fetch!(@palette, name)

  def tone(name), do: Map.fetch!(@tones, name)

  def css(scope \\ nil), do: @base_css <> dark_css(scope)

  defp dark_css(nil), do: "@media (prefers-color-scheme: dark){#{rules(@dark_rules, "")}}"
  defp dark_css(scope), do: rules(@dark_rules, scope <> " ")

  defp rules(rules, prefix) do
    Enum.map_join(rules, fn {selector, declarations} ->
      "#{prefix}#{selector}{#{declarations}}"
    end)
  end

  def text(size, color),
    do: "font-family: #{@sans}; #{Map.fetch!(@type_scale, size)}; color: #{color(color)}"

  def tag(tone, :sm),
    do: "#{tag_base(tone)}; padding: 3px 7px; font-size: 10px; line-height: normal"

  def tag(tone, :md),
    do: "#{tag_base(tone)}; padding: 4px 8px; font-size: 11px; line-height: normal"

  defp tag_base(tone) do
    %{line: line, bg: bg, ink: ink} = tone(tone)

    "display: inline-block; border: 1px solid #{line}; background: #{bg}; color: #{ink}; border-radius: 6px; font-family: #{@mono}; letter-spacing: 0.06em"
  end

  def chip(tone) do
    %{line: line, bg: bg, ink: ink} = tone(tone)

    "display: inline-block; padding: 5px 10px; border-radius: 8px; border: 1px solid #{line}; background: #{bg}; color: #{ink}; font-family: #{@mono}; font-size: 12px; line-height: normal"
  end
end
