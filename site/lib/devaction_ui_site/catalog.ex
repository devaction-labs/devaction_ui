defmodule DevactionUISite.Catalog do
  @moduledoc """
  The pages of the component documentation: one per component, grouped by what it is for, in the order of the
  sidebar. A page's title comes from the module name, its summary from the first sentence of the module's
  `@moduledoc`, and its examples from `examples/<slug>_<nn>.html.heex`; nothing here is written twice.
  """

  alias DevactionUISite.Reference

  @categories [
    {"Base",
     ~w(Accordion Alert Avatar Badge Banner Button Callout CodeBlock DescriptionList EmptyState Kbd Panel Progress Separator Skeleton Spinner Stat Tabs Tag Timeline)},
    {"Overlay",
     ~w(CommandPalette ConfirmDialog CookieConsent DangerDialog Drawer Dropdown Modal NotificationCenter Popover ProgressToast ToastGroup Tooltip)},
    {"Form",
     ~w(Autocomplete Choice ColorPicker Combobox CopyField DatePicker Dropzone Editor Field FilterMenu FilterPill InputGroup MoneyInput NumberInput PasswordStrength Pillbox Segmented SignatureField Slider Switch Textarea Timer)},
    {"Navigation", ~w(Breadcrumb PageHeader Pagination Sidebar Stepper Steps)},
    {"Data", ~w(Calendar Chart DataTable Kanban PdfViewer Pricing)},
    {"AI", ~w(AiPrompt Aura ChatBubble)}
  ]

  @groups (for {category, names} <- @categories do
             entries =
               for name <- names do
                 module = Module.concat(DevactionUI, name)

                 title =
                   name
                   |> Macro.underscore()
                   |> String.replace("_", " ")
                   |> String.capitalize()
                   |> String.replace_prefix("Ai ", "AI ")

                 %{
                   slug: Macro.underscore(name),
                   title: title,
                   module: module,
                   modules: [module],
                   category: category
                 }
               end

             {category, Enum.sort_by(entries, & &1.title)}
           end)

  @entries Enum.flat_map(@groups, fn {_category, entries} -> entries end)

  @doc "The components, grouped by category, in the order of the sidebar."
  def groups, do: @groups

  @doc "Every component in order."
  def all, do: @entries

  @doc "The category a component belongs to."
  def group_of(%{category: category}), do: category

  @doc "A component by its slug."
  def fetch(slug) do
    case Enum.find(@entries, &(&1.slug == slug)) do
      nil -> :error
      entry -> {:ok, entry}
    end
  end

  @doc "What a component is, in one sentence: the start of its module documentation."
  def summary(%{module: module}), do: Reference.summary(module)

  @doc "The groups with only the components that match `query` by title, summary or module name."
  def search(query) do
    needle = fold(query)

    for {category, entries} <- @groups,
        found = Enum.filter(entries, &matches?(&1, needle)),
        found != [],
        do: {category, found}
  end

  @doc "The component before and the one after, `nil` at the ends."
  def neighbours(%{slug: slug}) do
    index = Enum.find_index(@entries, &(&1.slug == slug))
    {previous(index), Enum.at(@entries, index + 1)}
  end

  defp matches?(_entry, ""), do: true

  defp matches?(entry, needle) do
    [entry.title, summary(entry), Reference.short(entry.module)]
    |> Enum.join(" ")
    |> fold()
    |> String.contains?(needle)
  end

  defp fold(text) do
    text
    |> String.downcase()
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.trim()
  end

  defp previous(0), do: nil
  defp previous(index), do: Enum.at(@entries, index - 1)
end
