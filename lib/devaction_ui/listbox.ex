defmodule DevactionUI.Listbox do
  @moduledoc """
  A select with a panel of our own, for when the native `DevactionUI.Select` is not enough: options with a
  marker (an icon, an avatar, a swatch) and a line of description, groups, a search at the top of the panel,
  several choices at once, a button that empties the choice and a row that creates what the search did not
  find. For a short list with none of that, the native select is still the right one.

      <Listbox.listbox
        field={@form[:category_id]}
        label="Category"
        placeholder="Choose a category"
        options={[
          {"Work", [%{value: "dev", label: "Development", description: "Code, review and deploy"}]},
          %{value: "fin", label: "Finance", keywords: "money invoice"}
        ]}
      />

  Options are maps `%{value, label}` with the optional `description` (a quiet line under the label),
  `keywords` (more words the search finds it by, not shown) and `disabled`; a `{label, options}` tuple is a
  group with a heading. The `option_marker` slot draws something before each label and gets the option as it
  was given, so it may carry anything else (an `icon`, an `avatar`).

  `searchable` puts a field at the top of the panel that filters while you type, ignoring case and accents,
  by the label and the keywords; `empty` is what shows when nothing is left, with `%{term}` for the text
  typed. With `create` (`"Create “%{term}”"`) the last row offers to create the text typed when no option is
  called exactly that; choosing it sends `on_create` to the LiveView (`phx-target` points it at a component)
  with `%{"id" => id, "term" => text}`, and the LiveView adds the option and sets the value; `create_hint`
  is a small text at the end of that row (the key that chooses it). `search_clear_label` names a button in the
  search field that empties what was typed.

  `multiple` keeps the panel open while choosing and sends a list (`name[]`, an empty list when nothing is
  chosen). The button says `count_text` (`"%{count} chosen"`) or, without it, the labels joined by commas,
  so it never changes height. `indicator` is `:check` (a mark at the end of the row, the default) or
  `:checkbox` (a box at the start). `prefix` is a fixed text before the choice on the button (`Compare to`).

  The panel is `position: fixed`, put by the hook under the button (`position={:top}` for above, `align` for
  the side), so an ancestor with `overflow: hidden` does not cut it; it opens on the other side when the wanted
  one has no room and shortens its list when neither has.

  The keyboard is the ARIA pattern: ↓ ↑ on the button open it, ↑ ↓ Home End move, Enter (and Space without a
  search) chooses, Esc closes and returns to the button, Tab leaves; without a search, typing letters jumps to
  the option that starts with them. The value is in hidden inputs and the hook fires `input` on them, so the
  form's `phx-change` hears every choice. The chosen value is the caller's, as in any LiveView field: a form
  that re-renders should hold `value` (with `phx-change`).

  `field={@form[:category_id]}` fills the id, the name, the value and the error (see
  `DevactionUI.FormField`). The library knows no language: every word is an attribute.
  """
  use Phoenix.Component

  alias DevactionUI.FormField
  alias Phoenix.LiveView.JS

  attr :id, :string, default: nil, doc: "required unless a `field` gives it"

  attr :name, :string,
    default: nil,
    doc: "required unless a `field` gives it; `[]` is added when `multiple`"

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc:
      "a form field (`@form[:category_id]`): gives the `id`, the `name`, the value and the error"

  attr :options, :list,
    required: true,
    doc:
      "`%{value, label}` maps (with `description`, `keywords` and `disabled` optional) and `{label, options}` groups"

  attr :value, :any, default: nil, doc: "the chosen value, or a list of them when `multiple`"
  attr :label, :string, required: true, doc: "what is being chosen, for assistive technology"
  attr :placeholder, :string, required: true, doc: "shown on the button when nothing is chosen"

  attr :multiple, :boolean,
    default: false,
    doc: "several choices; the panel stays open while choosing"

  attr :indicator, :atom,
    values: [:check, :checkbox],
    default: :check,
    doc: "how a chosen option is marked: a check at the end or a box at the start"

  attr :count_text, :string,
    default: nil,
    doc: "the button text of a multiple choice, with `%{count}`; the labels joined when nil"

  attr :prefix, :string, default: nil, doc: "a fixed text on the button before the choice"
  attr :searchable, :boolean, default: false, doc: "a search field at the top of the panel"
  attr :search_placeholder, :string, default: nil

  attr :empty, :string,
    default: nil,
    doc: "shown when the search finds nothing; `%{term}` is the text typed"

  attr :create, :string,
    default: nil,
    doc: "the text of the row that creates what was typed, with `%{term}`; needs `on_create`"

  attr :on_create, :string,
    default: nil,
    doc: "the event sent with `%{\"id\" => id, \"term\" => text}` when the create row is chosen"

  attr :create_hint, :string,
    default: nil,
    doc: "a small text at the end of the create row, such as the key that chooses it (`Enter`)"

  attr :clear_label, :string,
    default: nil,
    doc: "the name of the button that empties the choice; none when nil"

  attr :search_clear_label, :string,
    default: nil,
    doc:
      "the name of the button in the search field that empties what was typed; none when nil, drawn with `clear_icon`"

  attr :size, :atom, values: [:sm, :md, :lg], default: :md
  attr :position, :atom, values: [:bottom, :top], default: :bottom, doc: "where the panel opens"

  attr :align, :atom,
    values: [:start, :end],
    default: :start,
    doc: "the side the panel lines up with"

  attr :panel_class, :any, default: nil, doc: "classes of the panel, such as a width (`w-72`)"
  attr :disabled, :boolean, default: false
  attr :required, :boolean, default: false

  attr :show_label, :boolean,
    default: false,
    doc: "draws `label` above the field instead of leaving it for assistive technology only"

  attr :help, :string, default: nil, doc: "a line of explanation under the field"
  attr :error, :string, default: nil, doc: "the message under the field; also marks it invalid"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-target)

  slot :icon, doc: "an icon at the start of the button"
  slot :chevron_icon, doc: "the arrow at the end of the button; turns over when open"
  slot :search_icon, doc: "the magnifier in the search field"
  slot :clear_icon, doc: "the icon of the clear button"
  slot :check_icon, doc: "the mark of a chosen option (`indicator={:check}`) and in its box"
  slot :create_icon, doc: "drawn before the text of the create row"
  slot :option_marker, doc: "drawn before the label of each option; gets the option as given"

  @doc "A select whose panel the library draws: groups, descriptions, search, several choices, create."
  @spec listbox(map()) :: Phoenix.LiveView.Rendered.t()
  def listbox(assigns) do
    assigns =
      assigns
      |> FormField.put(value: :raw)
      |> FormField.require!([:id, :name], "listbox/1")

    {groups, options} = groups(assigns.options)
    values = values(assigns.value, assigns.multiple)
    chosen = Enum.filter(options, &(&1.value in values))

    assigns =
      assign(assigns,
        error: FormField.error(assigns),
        groups: groups,
        values: values,
        chosen: chosen,
        input_name: if(assigns.multiple, do: assigns.name <> "[]", else: assigns.name),
        button: button_text(assigns, chosen)
      )

    ~H"""
    <div
      id={@id}
      phx-hook="DevactionUI.Listbox"
      data-placeholder={@placeholder}
      data-count-text={@count_text}
      data-multiple={@multiple && "true"}
      data-create-event={@on_create}
      data-create-target={@rest[:"phx-target"]}
      data-position={@position}
      data-align={@align}
      class={["listbox relative", @class]}
      {Map.drop(@rest, [:"phx-target"])}
    >
      <span data-values hidden>
        <input
          :if={@multiple}
          type="hidden"
          name={@input_name}
          value=""
          data-sentinel
          disabled={@disabled}
        />
        <input
          :for={value <- (@multiple && @values) || [List.first(@values) || ""]}
          type="hidden"
          name={@input_name}
          value={value}
          disabled={@disabled}
        />
      </span>
      <label
        id={"#{@id}-label"}
        for={"#{@id}-trigger"}
        class={(@show_label && "mb-1.5 block text-[13px] font-medium text-ink") || "sr-only"}
      >
        {@label}
      </label>
      <div class="relative">
        <button
          type="button"
          id={"#{@id}-trigger"}
          data-trigger
          aria-haspopup="listbox"
          aria-expanded="false"
          aria-controls={"#{@id}-list"}
          aria-labelledby={"#{@id}-label #{@id}-current"}
          aria-describedby={described_by(@id, @help, @error)}
          aria-invalid={@error && "true"}
          aria-required={@required && "true"}
          disabled={@disabled}
          phx-mounted={JS.ignore_attributes(["aria-expanded"])}
          class={[
            "listbox-trigger",
            size_class(@size),
            @error && "listbox-trigger-invalid"
          ]}
        >
          <span :if={@icon != []} class="listbox-icon" aria-hidden="true">{render_slot(@icon)}</span>
          <span :if={@prefix} class="shrink-0 text-muted">{@prefix}</span>
          <span
            :if={@option_marker != [] and not @multiple}
            data-current-marker
            class="listbox-marker empty:hidden"
            aria-hidden="true"
          >{@chosen != [] && render_slot(@option_marker, hd(@chosen).raw)}</span>
          <span
            id={"#{@id}-current"}
            data-current
            class={[
              "min-w-0 flex-1 truncate",
              @prefix && "font-medium",
              @clear_label && "pr-8",
              @button.muted && "text-muted-2"
            ]}
          >
            {@button.text}
          </span>
          <span class="listbox-chevron" aria-hidden="true">
            {render_slot(@chevron_icon)}<span :if={@chevron_icon == []}>⌄</span>
          </span>
        </button>
        <button
          :if={@clear_label}
          type="button"
          data-clear
          aria-label={@clear_label}
          hidden={@chosen == []}
          disabled={@disabled}
          phx-mounted={JS.ignore_attributes(["hidden"])}
          class="listbox-clear"
        >
          {render_slot(@clear_icon)}<span :if={@clear_icon == []} aria-hidden="true">×</span>
        </button>
      </div>
      <div
        data-panel
        hidden
        phx-mounted={JS.ignore_attributes(["hidden", "style"])}
        class={["listbox-panel", position_class(@position), align_class(@align), @panel_class]}
      >
        <label :if={@searchable} class="listbox-search">
          <span
            :if={@search_icon != []}
            class="size-4 shrink-0 text-muted [&>*]:size-full"
            aria-hidden="true"
          >
            {render_slot(@search_icon)}
          </span>
          <input
            type="text"
            data-search
            role="combobox"
            aria-expanded="true"
            aria-autocomplete="list"
            aria-controls={"#{@id}-list"}
            aria-label={@label}
            placeholder={@search_placeholder}
            autocomplete="off"
            phx-mounted={JS.ignore_attributes(["aria-activedescendant"])}
          />
          <button
            :if={@search_clear_label}
            type="button"
            data-search-clear
            aria-label={@search_clear_label}
            hidden
            phx-mounted={JS.ignore_attributes(["hidden"])}
            class="listbox-search-clear"
          >
            {render_slot(@clear_icon)}<span :if={@clear_icon == []} aria-hidden="true">×</span>
          </button>
        </label>
        <div
          id={"#{@id}-list"}
          role="listbox"
          data-list
          tabindex={!@searchable && "-1"}
          aria-label={@label}
          aria-multiselectable={@multiple && "true"}
          phx-mounted={JS.ignore_attributes(["aria-activedescendant"])}
          class="listbox-list"
        >
          <div
            :for={{group, index} <- Enum.with_index(@groups)}
            role={group.label && "group"}
            aria-labelledby={group.label && "#{@id}-group-#{index}"}
            data-group
            phx-mounted={JS.ignore_attributes(["hidden"])}
            class="flex flex-col gap-0.5"
          >
            <div :if={group.label} id={"#{@id}-group-#{index}"} class="listbox-group">
              {group.label}
            </div>
            <div
              :for={option <- group.options}
              id={"#{@id}-option-#{option.index}"}
              role="option"
              data-value={option.value}
              data-label={option.label}
              data-keywords={option.keywords}
              aria-selected={to_string(option.value in @values)}
              aria-disabled={option.disabled && "true"}
              phx-mounted={JS.ignore_attributes(["hidden", "data-active"])}
              class="listbox-option group/option"
            >
              <span :if={@multiple and @indicator == :checkbox} class="listbox-box" aria-hidden="true">
                {render_slot(@check_icon)}<span :if={@check_icon == []}>✓</span>
              </span>
              <span :if={@option_marker != []} data-marker class="listbox-marker" aria-hidden="true">
                {render_slot(@option_marker, option.raw)}
              </span>
              <span class="flex min-w-0 flex-1 flex-col gap-px">
                <span class="listbox-label">{option.label}</span>
                <span :if={option.description} class="listbox-description">
                  {option.description}
                </span>
              </span>
              <span :if={@indicator == :check} class="listbox-check" aria-hidden="true">
                {render_slot(@check_icon)}<span :if={@check_icon == []}>✓</span>
              </span>
            </div>
          </div>
          <div
            :if={@searchable and @empty}
            data-empty
            data-pattern={@empty}
            hidden
            phx-mounted={JS.ignore_attributes(["hidden"])}
            class="listbox-empty"
          >
          </div>
          <div
            :if={(@searchable and @create) && @on_create}
            id={"#{@id}-create"}
            role="option"
            aria-selected="false"
            data-create
            data-pattern={@create}
            hidden
            phx-mounted={JS.ignore_attributes(["hidden", "data-active"])}
            class="listbox-option listbox-create"
          >
            <span :if={@create_icon != []} class="listbox-marker" aria-hidden="true">
              {render_slot(@create_icon)}
            </span>
            <span data-create-text class="min-w-0 flex-1 truncate"></span>
            <span :if={@create_hint} class="listbox-hint">{@create_hint}</span>
          </div>
        </div>
      </div>
      <p :if={@help} id={"#{@id}-help"} class="m-0 mt-1.5 text-[13px] text-muted">{@help}</p>
      <p :if={@error} id={"#{@id}-error"} role="alert" class="m-0 mt-1.5 text-[13px] text-risk-fg">
        {@error}
      </p>
    </div>
    """
  end

  defp groups(options) do
    {groups, _index} =
      options
      |> Enum.map(fn
        {label, list} when is_list(list) -> {label, list}
        option -> {nil, [option]}
      end)
      |> Enum.reduce([], fn
        {nil, [option]}, [{nil, acc} | rest] -> [{nil, acc ++ [option]} | rest]
        group, acc -> [group | acc]
      end)
      |> Enum.reverse()
      |> Enum.map_reduce(0, fn {label, list}, index ->
        options = list |> Enum.with_index(index) |> Enum.map(fn {raw, at} -> option(raw, at) end)
        {%{label: label, options: options}, index + length(list)}
      end)

    {groups, Enum.flat_map(groups, & &1.options)}
  end

  defp option(raw, index) do
    %{
      index: index,
      raw: raw,
      value: FormField.text(raw.value),
      label: raw.label,
      description: Map.get(raw, :description),
      keywords: raw |> Map.get(:keywords) |> keywords(),
      disabled: Map.get(raw, :disabled, false)
    }
  end

  defp keywords(nil), do: nil
  defp keywords(words) when is_list(words), do: Enum.join(words, " ")
  defp keywords(words), do: words

  defp values(value, true),
    do: value |> List.wrap() |> Enum.map(&FormField.text/1) |> Enum.reject(&(&1 in [nil, ""]))

  defp values(nil, false), do: []
  defp values(value, false), do: [FormField.text(value)]

  defp button_text(assigns, []), do: %{text: assigns.placeholder, muted: true}

  defp button_text(%{multiple: true, count_text: text}, chosen) when is_binary(text),
    do: %{text: String.replace(text, "%{count}", to_string(length(chosen))), muted: false}

  defp button_text(_assigns, chosen),
    do: %{text: Enum.map_join(chosen, ", ", & &1.label), muted: false}

  defp described_by(id, help, error) do
    case Enum.reject([help && "#{id}-help", error && "#{id}-error"], &is_nil/1) do
      [] -> nil
      ids -> Enum.join(ids, " ")
    end
  end

  defp size_class(:sm), do: "listbox-sm"
  defp size_class(:md), do: nil
  defp size_class(:lg), do: "listbox-lg"

  defp position_class(:bottom), do: "top-full mt-1.5"
  defp position_class(:top), do: "bottom-full mb-1.5"

  defp align_class(:start), do: "left-0"
  defp align_class(:end), do: "right-0"
end
