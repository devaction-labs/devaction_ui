defmodule DevactionUISite.Project do
  @moduledoc """
  What the site says about the library it documents, read from the `mix.exs` of the package at compile time
  so a release never leaves the version or the repository out of date: the version, the repository and the
  address of a component's source file.
  """

  @mix Path.expand("../../../mix.exs", __DIR__)
  @external_resource @mix

  @source File.read!(@mix)
  @version ~r/@version "([^"]+)"/ |> Regex.run(@source) |> List.last()
  @repo ~r/@source_url "([^"]+)"/ |> Regex.run(@source) |> List.last()
  @short @version |> String.split(".") |> Enum.take(2) |> Enum.join(".")

  @doc "The full version of the package, as in its `mix.exs`."
  def version, do: @version

  @doc "The version without the patch, as the chips of the site show it (`0.1`)."
  def short_version, do: @short

  @doc "The address of the repository on GitHub."
  def repo_url, do: @repo

  @doc "Where a problem is reported."
  def issues_url, do: @repo <> "/issues/new"

  @doc "The address of the file of a component's module on GitHub."
  def source_url(module) do
    file = module |> Module.split() |> List.last() |> Macro.underscore()
    "#{@repo}/blob/main/lib/devaction_ui/#{file}.ex"
  end
end
