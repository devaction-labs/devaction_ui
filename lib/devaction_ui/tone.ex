defmodule DevactionUI.Tone do
  @moduledoc """
  The tones of the canvas as class strings, so every component that tints something (a callout, a finding,
  an alert, a progress bar) takes the same colors from the same tokens and flips with the theme.

  The five of meaning are `:risk`, `:warn`, `:ok`, `:info` and `:neutral`; `:indigo` and `:emerald` are the
  tints of people and of work in review (the default avatar, the \"reviewing\" dot); `:chart_1` to `:chart_4`
  are drawn from the `--chart-*` series colors, for what a chart or a calendar paints by series.

  `fill/1` is the solid of a bar and `dot/1` the status dot: the dot is the brighter green, indigo or amber
  of the canvas, the bar the same color as the text of the tone.

  The canvas names kinds by meaning (note, ai, tip, warning, decision); `from_kind/1` turns a kind into
  the tone it is drawn in.
  """

  @meaning [:risk, :warn, :ok, :info, :neutral]
  @tints [:indigo, :emerald]
  @series [:chart_1, :chart_2, :chart_3, :chart_4]

  @type t ::
          :risk
          | :warn
          | :ok
          | :info
          | :neutral
          | :indigo
          | :emerald
          | :chart_1
          | :chart_2
          | :chart_3
          | :chart_4
  @type kind :: t() | :ai | :warning | :decision | :tip | :note

  @doc "The tone a callout or alert kind is drawn in."
  @spec from_kind(kind()) :: t()
  def from_kind(kind) when kind in @meaning or kind in @tints or kind in @series, do: kind
  def from_kind(:ai), do: :warn
  def from_kind(:warning), do: :risk
  def from_kind(:decision), do: :ok
  def from_kind(:tip), do: :info
  def from_kind(:note), do: :neutral

  @doc "Border and background of a tinted surface."
  @spec surface(t()) :: String.t()
  def surface(:risk), do: "border-tag-risk-line bg-tag-risk-bg"
  def surface(:warn), do: "border-tag-warn-line bg-tag-warn-bg"
  def surface(:ok), do: "border-tag-ok-line bg-tag-ok-bg"
  def surface(:info), do: "border-tag-info-line bg-tag-info-bg"
  def surface(:neutral), do: "border-tag-neutral-line bg-tag-neutral-bg"
  def surface(:indigo), do: "border-tag-indigo-line bg-tag-indigo-bg"
  def surface(:emerald), do: "border-tag-emerald-line bg-tag-emerald-bg"
  def surface(:chart_1), do: "border-chart-1/30 bg-chart-1/10"
  def surface(:chart_2), do: "border-chart-2/30 bg-chart-2/10"
  def surface(:chart_3), do: "border-chart-3/30 bg-chart-3/10"
  def surface(:chart_4), do: "border-chart-4/30 bg-chart-4/10"

  @doc "Only the background of a tinted surface, for what has no border."
  @spec bg(t()) :: String.t()
  def bg(:risk), do: "bg-tag-risk-bg"
  def bg(:warn), do: "bg-tag-warn-bg"
  def bg(:ok), do: "bg-tag-ok-bg"
  def bg(:info), do: "bg-tag-info-bg"
  def bg(:neutral), do: "bg-tag-neutral-bg"
  def bg(:indigo), do: "bg-tag-indigo-bg"
  def bg(:emerald), do: "bg-tag-emerald-bg"
  def bg(:chart_1), do: "bg-chart-1/10"
  def bg(:chart_2), do: "bg-chart-2/10"
  def bg(:chart_3), do: "bg-chart-3/10"
  def bg(:chart_4), do: "bg-chart-4/10"

  @doc "The text color that goes on that surface."
  @spec text(t()) :: String.t()
  def text(:risk), do: "text-tag-risk-text"
  def text(:warn), do: "text-tag-warn-text"
  def text(:ok), do: "text-tag-ok-text"
  def text(:info), do: "text-tag-info-text"
  def text(:neutral), do: "text-tag-neutral-text"
  def text(:indigo), do: "text-tag-indigo-text"
  def text(:emerald), do: "text-tag-emerald-text"
  def text(:chart_1), do: "text-chart-1"
  def text(:chart_2), do: "text-chart-2"
  def text(:chart_3), do: "text-chart-3"
  def text(:chart_4), do: "text-chart-4"

  @doc "The darker text of the tone, for the title and body of a tinted alert or callout."
  @spec strong(t()) :: String.t()
  def strong(:risk), do: "text-tag-risk-strong"
  def strong(:warn), do: "text-tag-warn-strong"
  def strong(:ok), do: "text-tag-ok-strong"
  def strong(:info), do: "text-tag-info-strong"
  def strong(:neutral), do: "text-tag-neutral-strong"
  def strong(:indigo), do: "text-tag-indigo-strong"
  def strong(:emerald), do: "text-tag-emerald-strong"
  def strong(:chart_1), do: "text-chart-1"
  def strong(:chart_2), do: "text-chart-2"
  def strong(:chart_3), do: "text-chart-3"
  def strong(:chart_4), do: "text-chart-4"

  @doc "A solid fill of the tone, for bars."
  @spec fill(t()) :: String.t()
  def fill(:risk), do: "bg-missing"
  def fill(:warn), do: "bg-ai"
  def fill(:ok), do: "bg-tag-ok-text"
  def fill(:info), do: "bg-learn"
  def fill(:neutral), do: "bg-ink"
  def fill(:indigo), do: "bg-tag-indigo-text"
  def fill(:emerald), do: "bg-tag-emerald-text"
  def fill(:chart_1), do: "bg-chart-1"
  def fill(:chart_2), do: "bg-chart-2"
  def fill(:chart_3), do: "bg-chart-3"
  def fill(:chart_4), do: "bg-chart-4"

  @doc ~S|The solid of a status dot: the brighter shade the canvas draws "connected" and "reviewing" in.|
  @spec dot(t()) :: String.t()
  def dot(:risk), do: "bg-dot-risk"
  def dot(:warn), do: "bg-dot-warn"
  def dot(:ok), do: "bg-dot-ok"
  def dot(:info), do: "bg-dot-info"
  def dot(:neutral), do: "bg-dot-neutral"
  def dot(:indigo), do: "bg-dot-indigo"
  def dot(:emerald), do: "bg-dot-emerald"
  def dot(:chart_1), do: "bg-chart-1"
  def dot(:chart_2), do: "bg-chart-2"
  def dot(:chart_3), do: "bg-chart-3"
  def dot(:chart_4), do: "bg-chart-4"
end
