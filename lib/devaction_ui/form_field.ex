defmodule DevactionUI.FormField do
  @moduledoc """
  What the fields of the library read from a `Phoenix.HTML.FormField` (`field={@form[:title]}`): the `id`, the
  `name`, the value and the errors, so a form is written as with the core components or any kit that takes a
  field, and a field can replace one of them without rewiring the form.

  What the caller gives by hand wins: `id`, `name`, `value` and `error` passed next to `field` are kept. The
  errors are only shown once the person has used the input (`Phoenix.Component.used_input?/1`), as the core
  components do, so an empty form does not open in red.

  The library knows no language, so an error `{message, options}` is translated by the function the app sets:

      # config/config.exs
      config :devaction_ui, :translate_error, {MyAppWeb.CoreComponents, :translate_error}

  With none set, the `%{count}` style placeholders of the message are filled and the text is used as it is.
  """

  alias Phoenix.HTML.{Form, FormField}

  @doc "The messages of a field's errors, translated, or `[]` while the person has not used the input."
  @spec errors(FormField.t() | nil) :: [String.t()]
  def errors(nil), do: []

  def errors(%FormField{} = field) do
    if Phoenix.Component.used_input?(field), do: Enum.map(field.errors, &translate/1), else: []
  end

  @doc "One error of a changeset as text, through the `:translate_error` of the app when there is one."
  @spec translate({String.t(), keyword()} | String.t()) :: String.t()
  def translate(message) when is_binary(message), do: message

  def translate({message, opts} = error) do
    case Application.get_env(:devaction_ui, :translate_error) do
      {module, function} -> apply(module, function, [error])
      fun when is_function(fun, 1) -> fun.(error)
      nil -> interpolate(message, opts)
    end
  end

  defp interpolate(message, opts) do
    Enum.reduce(opts, message, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  @doc """
  Fills the assigns of a component from its `field`, keeping what the caller gave by hand, and sets
  `:field_errors` (`[]` without a field). `opts`:

    * `value:` — `:text` (the value as text, for an input), `:raw` (as it is: a `Date`, a list),
      `:checkbox` (fills `checked` from a boolean field), `:member` (fills `checked` when the component's
      `value` is in the field's list, for one box of a group), `:radio` (fills `checked` when the component's
      `value` is the field's) or `nil` (leaves the value alone)
    * `multiple:` — the name ends in `[]`
    * `id_suffix:` — appended to the field's id, for the boxes and options of a group (`"-sge"`)
  """
  @spec put(map(), keyword()) :: map()
  def put(assigns, opts \\ [])

  def put(%{field: %FormField{} = field} = assigns, opts) do
    name = if opts[:multiple], do: field.name <> "[]", else: field.name

    assigns
    |> fill(:id, field.id <> (opts[:id_suffix] || ""))
    |> fill(:name, name)
    |> fill_value(field, opts[:value])
    |> Phoenix.Component.assign(:field_errors, errors(field))
  end

  def put(assigns, _opts), do: Phoenix.Component.assign(assigns, :field_errors, [])

  @doc "The first error of the field when the caller gave none, for the components that show one message."
  @spec error(map()) :: String.t() | nil
  def error(%{error: error}) when error not in [nil, ""], do: error
  def error(%{field_errors: [first | _]}), do: first
  def error(_assigns), do: nil

  @doc "Raises when neither the caller nor a `field` gave the attributes a component cannot do without."
  @spec require!(map(), [atom()], String.t()) :: map()
  def require!(assigns, keys, component) do
    case Enum.filter(keys, &(Map.get(assigns, &1) in [nil, ""])) do
      [] ->
        assigns

      missing ->
        raise ArgumentError,
              "#{component} needs #{Enum.map_join(missing, " and ", &"`#{&1}`")}, or a `field` to take them from"
    end
  end

  defp fill(assigns, key, value) do
    if Map.has_key?(assigns, key) and Map.get(assigns, key) in [nil, ""],
      do: Phoenix.Component.assign(assigns, key, value),
      else: assigns
  end

  defp fill_value(assigns, field, :text),
    do: fill(assigns, :value, text(field.value))

  defp fill_value(assigns, field, :raw),
    do: fill(assigns, :value, field.value)

  defp fill_value(assigns, field, :checkbox),
    do: Phoenix.Component.assign(assigns, :checked, Form.normalize_value("checkbox", field.value))

  defp fill_value(assigns, field, :member) do
    values = field.value |> List.wrap() |> Enum.map(&text/1)
    Phoenix.Component.assign(assigns, :checked, text(assigns.value) in values)
  end

  defp fill_value(assigns, field, :radio),
    do: Phoenix.Component.assign(assigns, :checked, text(assigns.value) == text(field.value))

  defp fill_value(assigns, _field, nil), do: assigns

  @doc "A value as the text of an input: `nil` stays `nil`, a `Date` or a number becomes its string."
  @spec text(term()) :: String.t() | nil
  def text(nil), do: nil
  def text(value) when is_binary(value), do: value
  def text(%{__struct__: _} = value), do: to_string(value)
  def text(value) when is_atom(value) or is_number(value), do: to_string(value)
  def text(value), do: value |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
end
