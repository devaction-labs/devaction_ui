defmodule DevactionUISite.Catalog do
  @moduledoc """
  The pages of the component documentation: one per component, grouped by what it is for, in the order of the
  sidebar. A page's title comes from the module name, its summary from the first sentence of the module's
  `@moduledoc`, and its examples from `examples/<slug>_<nn>.html.heex`; nothing here is written twice.
  """

  alias DevactionUISite.Reference

  @categories [
    {"Base",
     ~w(Accordion Alert Avatar Badge Banner Button Callout CodeBlock DescriptionList EmptyState Kbd Panel Progress ScrollArea Separator Skeleton Spinner Stat Tabs Tag Timeline)},
    {"Overlay",
     ~w(CommandPalette ConfirmDialog ContextMenu CookieConsent DangerDialog Drawer Dropdown HoverCard Modal NotificationCenter Popover ProgressToast ToastGroup Tooltip)},
    {"Form",
     ~w(Autocomplete Choice ColorPicker Combobox CopyField DatePicker DateRange Dropzone Editor Field FilterMenu FilterPill InputGroup MoneyInput NumberInput OtpInput PasswordStrength Pillbox Segmented SignatureField Slider Switch Textarea TimeField Timer)},
    {"Navigation", ~w(Breadcrumb PageHeader Pagination Shell Sidebar Stepper Steps)},
    {"Data",
     ~w(Calendar Chart DataTable DiffView FileTree Kanban PdfViewer Pricing Resizable SortableList)},
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

  @since_v02 ~w(Banner ContextMenu CookieConsent CopyField DateRange DescriptionList DiffView Field FileTree
                FilterPill HoverCard NotificationCenter OtpInput PdfViewer Pricing Resizable Separator
                SortableList TimeField)

  @since_v03 ~w(ScrollArea Shell)

  @doc "The components, grouped by category, in the order of the sidebar."
  def groups, do: @groups

  @doc "Every component in order."
  def all, do: @entries

  @doc "The version a component came with: the ones added in v0.3 say 0.3, in v0.2 say 0.2, the rest say 0.1."
  def since(%{module: module}), do: since(Reference.short(module))
  def since(name) when name in @since_v03, do: "0.3"
  def since(name) when name in @since_v02, do: "0.2"
  def since(_name), do: "0.1"

  @doc "The version entry of the changelog a component was created in: `v0.3` while it is the next one, else `v0.2.0`."
  def release(topic), do: release_of(since(topic))

  defp release_of("0.3"), do: "v0.3"
  defp release_of(since), do: "v#{since}.0"

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
