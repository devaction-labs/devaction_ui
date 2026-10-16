defmodule DevactionUI.Tone do
  @moduledoc """
  The five tones of the canvas (`:risk`, `:warn`, `:ok`, `:info`, `:neutral`) as class strings, so every
  component that tints something (a callout, a finding, an alert, a progress bar) takes the same colors
  from the same tokens and flips with the theme.

  The canvas names kinds by meaning (note, ai, tip, warning, decision); `from_kind/1` turns a kind into
  the tone it is drawn in.
  """

  @type t :: :risk | :warn | :ok | :info | :neutral
  @type kind :: t() | :ai | :warning | :decision | :tip | :note

  @doc "The tone a callout or alert kind is drawn in."
  @spec from_kind(kind()) :: t()
  def from_kind(kind) when kind in [:risk, :warn, :ok, :info, :neutral], do: kind
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

  @doc "The text color that goes on that surface."
  @spec text(t()) :: String.t()
  def text(:risk), do: "text-tag-risk-text"
  def text(:warn), do: "text-tag-warn-text"
  def text(:ok), do: "text-tag-ok-text"
  def text(:info), do: "text-tag-info-text"
  def text(:neutral), do: "text-tag-neutral-text"

  @doc "The darker text of the tone, for the title and body of a tinted alert or callout."
  @spec strong(t()) :: String.t()
  def strong(:risk), do: "text-tag-risk-strong"
  def strong(:warn), do: "text-tag-warn-strong"
  def strong(:ok), do: "text-tag-ok-strong"
  def strong(:info), do: "text-tag-info-strong"
  def strong(:neutral), do: "text-tag-neutral-strong"

  @doc "A solid fill of the tone, for bars and dots."
  @spec fill(t()) :: String.t()
  def fill(:risk), do: "bg-missing"
  def fill(:warn), do: "bg-ai"
  def fill(:ok), do: "bg-tag-ok-text"
  def fill(:info), do: "bg-learn"
  def fill(:neutral), do: "bg-ink"
end
