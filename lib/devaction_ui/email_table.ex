defmodule DevactionUI.EmailTable do
  @moduledoc """
  The tabular parts of an e-mail: label and value rows, the lists of findings, scope items and events, numbered
  steps and a row of numbers.

  Each is a table with inline styles, with the `em-line-b`, `em-soft`, `em-ink` and `em-panel` classes that the
  dark mode of `DevactionUI.Email.document/1` restyles. The lists reuse `DevactionUI.EmailTag` for their labels.
  """

  use Phoenix.Component

  alias DevactionUI.Email.Style
  alias DevactionUI.EmailTag

  @tones [:risk, :warn, :ok, :info, :neutral]

  attr :rest, :global

  slot :row, required: true, doc: "a line: the value is the content" do
    attr :label, :string, required: true
  end

  @doc """
  The details of one thing as lines: the label on the left in the soft color, the value on the right.

  ## Example

      <.details>
        <:row label="Device">Firefox on Linux</:row>
        <:row label="When">Oct 16, 09:12</:row>
      </.details>
  """
  @spec details(map()) :: Phoenix.LiveView.Rendered.t()
  def details(assigns) do
    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      width="100%"
      style="width: 100%; border-collapse: separate; border-spacing: 0; margin: 0 0 24px"
      {@rest}
    >
      <tbody>
        <tr :for={row <- @row}>
          <td
            class="em-line-b em-soft"
            style={"padding: 11px 0; border-bottom: 1px solid #{Style.color(:rule)}; font-family: #{Style.sans()}; font-size: 14px; line-height: normal; color: #{Style.color(:soft)}; width: 42%"}
          >
            {row.label}
          </td>
          <td
            class="em-line-b em-ink"
            style={"padding: 11px 0; border-bottom: 1px solid #{Style.color(:rule)}; font-family: #{Style.sans()}; font-size: 14px; line-height: normal; color: #{Style.color(:ink)}; font-weight: 500; text-align: right"}
          >
            {render_slot(row)}
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  slot :item, required: true, doc: "a finding" do
    attr :tone, :atom, values: @tones, required: true
    attr :tag, :string, required: true, doc: "the label of the tag, in capitals"
    attr :title, :string, required: true
    attr :location, :string, required: true, doc: "where, in mono: a file and a line"
  end

  attr :rest, :global

  @doc """
  A list of findings: a tag, a bold title and the place in mono.

  ## Example

      <.finding_list>
        <:item tone={:risk} tag="RISK" title="Unscoped query" location="lib/billing.ex:112" />
        <:item tone={:info} tag="TIP" title="Extract the helper" location="lib/billing.ex:140" />
      </.finding_list>
  """
  @spec finding_list(map()) :: Phoenix.LiveView.Rendered.t()
  def finding_list(assigns) do
    ~H"""
    <.frame {@rest}>
      <tr :for={item <- @item}>
        <td
          class="em-line-b"
          style={"padding: 12px 14px; border-bottom: 1px solid #{Style.color(:rule)}; vertical-align: top; width: 84px; line-height: normal"}
        >
          <EmailTag.tag tone={item.tone}>{item.tag}</EmailTag.tag>
        </td>
        <td
          class="em-line-b"
          style={"padding: 12px 14px 12px 0; border-bottom: 1px solid #{Style.color(:rule)}; font-family: #{Style.sans()}; font-size: 14px; line-height: 1.45; color: #{Style.color(:ink)}"}
        >
          <strong class="em-ink" style="font-weight: 600">{item.title}</strong>
          <br />
          <span style={"font-family: #{Style.mono()}; font-size: 12px; color: #{Style.color(:soft)}"}>{item.location}</span>
        </td>
      </tr>
    </.frame>
    """
  end

  slot :item, required: true, doc: "a line of the list; the content is the text" do
    attr :code, :string, required: true, doc: "the short mono code on the left"
  end

  attr :rest, :global

  @doc """
  A list of items with a short mono code on the left and a line of text.

  ## Example

      <.code_list>
        <:item code="1.1">Export invoices as CSV</:item>
        <:item code="1.2">Filter by client</:item>
      </.code_list>
  """
  @spec code_list(map()) :: Phoenix.LiveView.Rendered.t()
  def code_list(assigns) do
    ~H"""
    <.frame {@rest}>
      <tr :for={item <- @item}>
        <td
          class="em-line-b"
          style={"padding: 12px 14px; border-bottom: 1px solid #{Style.color(:rule)}; font-family: #{Style.mono()}; font-size: 12px; line-height: normal; color: #{Style.color(:soft)}; width: 44px; vertical-align: top"}
        >
          {item.code}
        </td>
        <td
          class="em-line-b em-ink"
          style={"padding: 12px 14px 12px 0; border-bottom: 1px solid #{Style.color(:rule)}; font-family: #{Style.sans()}; font-size: 14px; line-height: 1.5; color: #{Style.color(:ink)}"}
        >
          {render_slot(item)}
        </td>
      </tr>
    </.frame>
    """
  end

  slot :item, required: true, doc: "an event" do
    attr :title, :string, required: true
    attr :detail, :string, required: true, doc: "the line under the title"
    attr :tone, :atom, values: @tones, required: true
    attr :tag, :string, required: true, doc: "the label of the tag, in capitals"
    attr :date, :string, required: true, doc: "the date under the tag"
  end

  attr :rest, :global

  @doc """
  A list of dated events: a title and a detail on the left, a tag and the date on the right.

  ## Example

      <.event_list>
        <:item title="Renewal" detail="Hub API" tone={:warn} tag="30 DAYS" date="Nov 15" />
      </.event_list>
  """
  @spec event_list(map()) :: Phoenix.LiveView.Rendered.t()
  def event_list(assigns) do
    ~H"""
    <.frame {@rest}>
      <tr :for={item <- @item}>
        <td
          class="em-line-b em-ink"
          style={"padding: 12px 14px; border-bottom: 1px solid #{Style.color(:rule)}; font-family: #{Style.sans()}; font-size: 14px; line-height: normal; color: #{Style.color(:ink)}"}
        >
          <strong style="font-weight: 600">{item.title}</strong>
          <br />
          <span class="em-soft" style={"color: #{Style.color(:soft)}; font-size: 13px"}>{item.detail}</span>
        </td>
        <td
          class="em-line-b"
          style={"padding: 12px 14px; border-bottom: 1px solid #{Style.color(:rule)}; text-align: right; vertical-align: top; line-height: normal"}
        >
          <EmailTag.tag tone={item.tone}>{item.tag}</EmailTag.tag>
          <br />
          <span
            class="em-soft"
            style={"font-family: #{Style.sans()}; font-size: 13px; color: #{Style.color(:soft)}"}
          >{item.date}</span>
        </td>
      </tr>
    </.frame>
    """
  end

  attr :rest, :global
  slot :inner_block, required: true

  defp frame(assigns) do
    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      width="100%"
      class="em-line-b"
      style={"width: 100%; border-collapse: separate; border-spacing: 0; margin: 0 0 24px; border: 1px solid #{Style.color(:line)}; border-radius: 12px"}
      {@rest}
    >
      <tbody>
        {render_slot(@inner_block)}
      </tbody>
    </table>
    """
  end

  slot :step, required: true, doc: "a step; the content is its description" do
    attr :title, :string, required: true
    attr :current, :boolean, doc: "the step the reader is on, in the solid circle"
  end

  attr :rest, :global

  @doc """
  Numbered steps: a round number, a bold title and a line under it. The current step has the solid circle.

  ## Example

      <.steps>
        <:step title="Confirm your e-mail" current>You are here.</:step>
        <:step title="Connect GitHub">Pick the repositories.</:step>
      </.steps>
  """
  @spec steps(map()) :: Phoenix.LiveView.Rendered.t()
  def steps(assigns) do
    assigns = assign(assigns, :numbered, Enum.with_index(assigns.step, 1))

    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      width="100%"
      style="width: 100%; border-collapse: separate; border-spacing: 0; margin: 0 0 16px"
      {@rest}
    >
      <tbody>
        <tr :for={{step, number} <- @numbered}>
          <td style="width: 36px; padding: 0 0 14px; vertical-align: top">
            <span
              class={circle_class(Map.get(step, :current, false))}
              style={"display: inline-block; width: 26px; height: 26px; line-height: 26px; border-radius: 99px; text-align: center; font-family: #{Style.mono()}; font-size: 12px; #{circle(Map.get(step, :current, false))}"}
            >{number}</span>
          </td>
          <td
            class="em-ink"
            style={"padding: 2px 0 14px; font-family: #{Style.sans()}; font-size: 15px; line-height: 1.5; color: #{Style.color(:ink)}"}
          >
            <strong style="font-weight: 600">{step.title}</strong>
            <br />
            <span class="em-muted" style={"color: #{Style.color(:muted)}; font-size: 14px"}>{render_slot(
              step
            )}</span>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  defp circle_class(true), do: "em-step-on"
  defp circle_class(false), do: "em-panel em-muted"

  defp circle(true), do: "background: #{Style.color(:ink)}; color: #{Style.color(:on_ink)}"
  defp circle(false), do: "background: #{Style.color(:panel)}; color: #{Style.color(:muted)}"

  slot :stat, required: true, doc: "a number" do
    attr :value, :string, required: true
    attr :label, :string, required: true
  end

  attr :rest, :global

  @doc """
  A row of big numbers, each on a grey tile with its caption.

  ## Example

      <.stats>
        <:stat value="12" label="PRs reviewed" />
        <:stat value="3" label="Risks found" />
      </.stats>
  """
  @spec stats(map()) :: Phoenix.LiveView.Rendered.t()
  def stats(assigns) do
    assigns =
      assigns
      |> assign(:numbered, Enum.with_index(assigns.stat, 1))
      |> assign(:width, div(100, length(assigns.stat)))

    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      width="100%"
      style="width: 100%; border-collapse: separate; border-spacing: 0; margin: 0 0 28px"
      {@rest}
    >
      <tbody>
        <tr>
          <%= for {stat, number} <- @numbered do %>
            <td
              width={"#{@width}%"}
              class="em-panel"
              style={"padding: 16px; border-radius: 12px; background: #{Style.color(:panel)}; vertical-align: top"}
            >
              <div
                class="em-ink"
                style={"font-family: #{Style.sans()}; font-size: 28px; line-height: normal; font-weight: 600; letter-spacing: -0.02em; color: #{Style.color(:ink)}"}
              >
                {stat.value}
              </div>
              <div
                class="em-soft"
                style={"font-family: #{Style.sans()}; font-size: 13px; line-height: normal; color: #{Style.color(:soft)}; padding-top: 4px"}
              >
                {stat.label}
              </div>
            </td>
            <td :if={number < length(@stat)} width="8" style="width: 8px"></td>
          <% end %>
        </tr>
      </tbody>
    </table>
    """
  end
end
