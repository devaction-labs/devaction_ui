defmodule DevactionUISite.TemplateData do
  @moduledoc """
  The made-up data the full-page templates draw: a screen asks for the assigns of its `group` and `slug`, and
  the events it sends (the risk filter of the projects table) are answered here, so a template shows a table
  that really filters.
  """

  @projects [
    %{
      id: "sge",
      letter: "S",
      name: "SGE · Church Management",
      avatar: :risk,
      client: "Igreja Batista de Campo Limpo",
      milestone: "M3 · Reports",
      risk: "high",
      prs: 3,
      hours: 124,
      budget: 160,
      tone: :risk,
      updated: "2 h ago"
    },
    %{
      id: "ayram",
      letter: "A",
      name: "AYRAM web",
      avatar: :warn,
      client: "AYRAM Parcerias",
      milestone: "Retainer · out",
      risk: "medium",
      prs: 1,
      hours: 90,
      budget: 120,
      tone: :risk,
      updated: "5 h ago"
    },
    %{
      id: "hub",
      letter: "H",
      name: "Hub API",
      avatar: :ok,
      client: "[CLIENT]",
      milestone: "M2 · Webhooks",
      risk: "low",
      prs: 2,
      hours: 62,
      budget: 120,
      tone: :neutral,
      updated: "1 d ago"
    },
    %{
      id: "mesh",
      letter: "M",
      name: "Mesh API",
      avatar: :neutral,
      client: "[CLIENT]",
      milestone: "M1 · Contract",
      risk: "medium",
      prs: 0,
      hours: 8,
      budget: 40,
      tone: :neutral,
      updated: "1 d ago"
    },
    %{
      id: "app",
      letter: "D",
      name: "DevAction IA · App",
      avatar: :warn,
      client: "Internal",
      milestone: "Store beta",
      risk: "high",
      prs: 4,
      hours: 210,
      budget: 240,
      tone: :risk,
      updated: "2 d ago"
    },
    %{
      id: "site",
      letter: "S",
      name: "Company website",
      avatar: :neutral,
      client: "[CLIENT]",
      milestone: "Maintenance",
      risk: "low",
      prs: 0,
      hours: 6,
      budget: 20,
      tone: :neutral,
      updated: "5 d ago"
    },
    %{
      id: "ui",
      letter: "D",
      name: "DevAction UI",
      avatar: :neutral,
      client: "Internal",
      milestone: "v0.2",
      risk: "low",
      prs: 2,
      hours: 46,
      budget: 60,
      tone: :neutral,
      updated: "3 d ago"
    },
    %{
      id: "crm",
      letter: "C",
      name: "Agency CRM",
      avatar: :info,
      client: "Internal",
      milestone: "Discovery",
      risk: "medium",
      prs: 0,
      hours: 4,
      budget: 30,
      tone: :neutral,
      updated: "1 w ago"
    }
  ]

  @tab_icons %{
    "overview" => "dashboard-square-01",
    "projects" => "folder-01",
    "reviews" => "git-pull-request",
    "findings" => "alert-02",
    "documents" => "file-01"
  }

  @risks %{
    "high" => %{label: "High", variant: :risk, icon: "alert-02"},
    "medium" => %{label: "Medium", variant: :warn, icon: "alert-02"},
    "low" => %{label: "Low", variant: :ok, icon: "checkmark-circle-02"}
  }

  @doc "The assigns a screen starts with."
  def assigns("app", "projects"),
    do: %{projects: @projects, risk: "all", sort: nil, tab_icons: @tab_icons}

  def assigns(_group, _slug), do: %{}

  @doc "The projects that match the risk filter (`all` or a risk), in the order of the sort."
  def rows(projects, risk, sort), do: projects |> visible(risk) |> sorted(sort)

  defp visible(projects, "all"), do: projects
  defp visible(projects, risk), do: Enum.filter(projects, &(&1.risk == risk))

  defp sorted(projects, nil), do: projects
  defp sorted(projects, {"risk", direction}), do: Enum.sort_by(projects, &rank/1, direction)

  @doc "The sort a click on the header of a column leads to: descending, ascending, none."
  def next_sort(key, {key, :desc}), do: {key, :asc}
  def next_sort(key, {key, :asc}), do: nil
  def next_sort(key, _sort), do: {key, :desc}

  @doc "The label, the tag variant and the icon of a risk."
  def risk(key), do: Map.fetch!(@risks, key)

  @doc "How much of the budget the hours are, from 0 to 100."
  def percent(%{hours: hours, budget: budget}), do: min(round(hours * 100 / budget), 100)

  defp rank(%{risk: risk}), do: Enum.find_index(["low", "medium", "high"], &(&1 == risk))
end
