defmodule DevactionUISite.ReviewDemo do
  @moduledoc """
  The made-up code review behind the `FileTree` and `DiffView` examples: the changed files, the diffs, a
  conversation on a line, and the small state machine the interactive examples share (open folders, the
  selected file, the filter, the search, threads, replies and applied suggestions). Every reducer takes the
  state and the event's params and returns the new state; what the demo does not know it leaves alone.
  """
  use Phoenix.Component

  alias DevactionUI.DiffView

  @milestone "lib/sge/contracts/milestone.ex"

  @nodes [
    %{path: "lib", type: :dir},
    %{path: "lib/sge", type: :dir, depth: 1},
    %{
      path: @milestone,
      type: :file,
      name: "contracts/milestone.ex",
      depth: 2,
      status: :modified,
      additions: 18,
      deletions: 6,
      findings: 2,
      level: :risk
    },
    %{
      path: "lib/sge/contracts/scope.ex",
      type: :file,
      name: "contracts/scope.ex",
      depth: 2,
      status: :modified,
      additions: 9,
      deletions: 3,
      findings: 1,
      level: :warn
    },
    %{
      path: "lib/sge/billing/invoice.ex",
      type: :file,
      name: "billing/invoice.ex",
      depth: 2,
      status: :added,
      additions: 64
    },
    %{path: "lib/sge_web", type: :dir, depth: 1},
    %{
      path: "lib/sge_web/live/milestone_live.ex",
      type: :file,
      name: "live/milestone_live.ex",
      depth: 2,
      status: :modified,
      additions: 22,
      deletions: 11,
      findings: 1,
      level: :warn
    },
    %{
      path: "lib/sge_web/live/legacy_report.ex",
      type: :file,
      name: "live/legacy_report.ex",
      depth: 2,
      status: :deleted,
      deletions: 48
    },
    %{path: "test", type: :dir},
    %{
      path: "test/sge/milestone_test.exs",
      type: :file,
      name: "sge/milestone_test.exs",
      depth: 1,
      status: :added,
      additions: 41
    },
    %{
      path: "priv/repo/migrations/20261014_add_due_on.exs",
      type: :file,
      name: "migrations/20261014_add_due_on.exs",
      depth: 0,
      status: :added,
      additions: 12
    }
  ]

  @milestone_hunks [
    %{
      lines: [
        %{old: 12, new: 12, kind: :context, text: "defmodule Sge.Contracts.Milestone do"},
        %{old: 13, new: 13, kind: :context, text: "  use Ecto.Schema"},
        %{old: 14, new: 14, kind: :context, text: "  import Ecto.Changeset"},
        %{old: 15, new: nil, kind: :del, text: "  @required ~w(title amount contract_id)a"},
        %{
          old: nil,
          new: 15,
          kind: :add,
          text: "  @required ~w(title amount contract_id due_on)a"
        },
        %{old: 16, new: 16, kind: :context, text: ""},
        %{old: 17, new: 17, kind: :context, text: "  def changeset(milestone, attrs) do"},
        %{
          old: nil,
          new: 18,
          kind: :add,
          text: "    milestone |> cast(attrs, @required ++ [:notes])"
        },
        %{old: nil, new: 19, kind: :add, text: "    |> validate_required(@required)"},
        %{
          old: nil,
          new: 20,
          kind: :add,
          text: "    |> validate_number(:amount, greater_than: 0)"
        },
        %{old: 18, new: nil, kind: :del, text: "    cast(milestone, attrs, @required)"},
        %{old: 19, new: 21, kind: :context, text: "  end"},
        %{old: 20, new: 22, kind: :context, text: "end"}
      ]
    }
  ]

  @scope_hunks [
    %{
      header: "@@ -8,4 +8,6 @@ defmodule Sge.Contracts.Scope do",
      lines: [
        %{old: 8, new: 8, kind: :context, text: "  schema \"scopes\" do"},
        %{old: 9, new: nil, kind: :del, text: "    field :hours, :integer"},
        %{old: nil, new: 9, kind: :add, text: "    field :hours, :integer, default: 0"},
        %{old: nil, new: 10, kind: :add, text: "    field :billable?, :boolean, default: true"},
        %{old: 10, new: 11, kind: :context, text: "  end"}
      ]
    },
    %{
      header: "@@ -31,3 +33,5 @@",
      lines: [
        %{old: 31, new: 33, kind: :context, text: "  def total(scope) do"},
        %{old: 32, new: nil, kind: :del, text: "    scope.hours * scope.rate"},
        %{old: nil, new: 34, kind: :add, text: "    Decimal.mult(scope.hours, scope.rate)"},
        %{old: 33, new: 35, kind: :context, text: "  end"}
      ]
    }
  ]

  @doc "The changed files as the `nodes` of a `FileTree`."
  def nodes, do: @nodes

  @doc "The lines added and removed by a file, `{additions, deletions}`."
  def stat(path) do
    node = Enum.find(@nodes, &(&1.path == path))
    {Map.get(node, :additions, 0), Map.get(node, :deletions, 0)}
  end

  @doc "The path of the file the review opens on."
  def milestone, do: @milestone

  @doc "The diff of the first file, as the artboard shows it."
  def milestone_hunks, do: @milestone_hunks

  @doc "A small diff with two hunks, each with a header."
  def scope_hunks, do: @scope_hunks

  @doc "The messages of the conversation on line 18 of the first file."
  def messages do
    [
      %{
        id: "m1",
        author: "DevAction Reviewer",
        initials: "AI",
        time: "now",
        ai: true,
        text:
          "due_on is now required, but the old milestones have no date. The migration has to fill the existing records first, otherwise updating any old milestone fails."
      },
      %{
        id: "m2",
        author: "Alex",
        initials: "AN",
        time: "2 min ago",
        ai: false,
        text:
          "Makes sense. Can you suggest the conditional validation while the migration has not run?",
        suggestion: %{
          from: "    |> validate_required(@required)",
          to: "    |> validate_required(@required -- [:due_on])"
        }
      }
    ]
  end

  @doc "The state of the interactive examples."
  def state do
    %{
      open: ["lib", "lib/sge", "test"],
      selected: @milestone,
      filter: :all,
      query: "",
      viewed: [],
      files: %{@milestone => @milestone_hunks, "lib/sge/contracts/scope.ex" => @scope_hunks},
      threads: %{{@milestone, 18, :new} => %{resolved: false, messages: messages()}}
    }
  end

  @doc "The diff of a file; a file the demo has no diff for gets a one-line change."
  def hunks(%{files: files}, path) do
    Map.get_lazy(files, path, fn ->
      [
        %{
          lines: [
            %{old: 1, new: 1, kind: :context, text: "# #{Path.basename(path)}"},
            %{old: 2, new: nil, kind: :del, text: "old line"},
            %{old: nil, new: 2, kind: :add, text: "new line"}
          ]
        }
      ]
    end)
  end

  @doc "The threads of the selected file as `{line, side, thread}`, by line."
  def threads(%{selected: path, threads: threads}),
    do: for({{^path, line, side}, thread} <- Enum.sort(threads), do: {line, side, thread})

  @filters %{"all" => :all, "findings" => :findings, "new" => :new}

  @doc "Selects a file."
  def select(state, %{"path" => path}), do: %{state | selected: path}
  def select(state, _params), do: state

  @doc "Opens a closed folder and closes an open one."
  def toggle(%{open: open} = state, %{"path" => path}) do
    %{state | open: (path in open && List.delete(open, path)) || [path | open]}
  end

  def toggle(state, _params), do: state

  @doc "Changes the filter to one of `all`, `findings` or `new`."
  def filter(state, %{"filter" => filter}) when is_map_key(@filters, filter),
    do: %{state | filter: Map.fetch!(@filters, filter)}

  def filter(state, _params), do: state

  @doc "Sets the search text."
  def search(state, %{"query" => query}) when is_binary(query), do: %{state | query: query}
  def search(state, _params), do: state

  @doc "Marks the file as viewed, or not."
  def view(%{viewed: viewed} = state, %{"path" => path}),
    do: %{state | viewed: (path in viewed && List.delete(viewed, path)) || [path | viewed]}

  def view(state, _params), do: state

  @doc "Opens a new thread on a line, reopens a resolved one, and closes an empty one."
  def comment(%{selected: path, threads: threads} = state, %{"line" => line} = params) do
    key = {path, to_int(line), side(params)}
    %{state | threads: toggle_thread(threads, key, Map.get(threads, key))}
  end

  def comment(state, _params), do: state

  defp toggle_thread(threads, key, nil),
    do: Map.put(threads, key, %{resolved: false, messages: []})

  defp toggle_thread(threads, key, %{resolved: true} = thread),
    do: Map.put(threads, key, %{thread | resolved: false})

  defp toggle_thread(threads, key, %{messages: []}), do: Map.delete(threads, key)
  defp toggle_thread(threads, _key, _thread), do: threads

  @doc "Resolves a thread, or drops it when nobody has written in it."
  def resolve(%{selected: path, threads: threads} = state, %{"line" => line} = params) do
    key = {path, to_int(line), side(params)}
    %{state | threads: close_thread(threads, key, Map.get(threads, key))}
  end

  def resolve(state, _params), do: state

  defp close_thread(threads, _key, nil), do: threads
  defp close_thread(threads, key, %{messages: []}), do: Map.delete(threads, key)
  defp close_thread(threads, key, thread), do: Map.put(threads, key, %{thread | resolved: true})

  @doc "Adds the reply a person wrote to the thread."
  def reply(
        %{selected: path, threads: threads} = state,
        %{"line" => line, "body" => body} = params
      ) do
    key = {path, to_int(line), side(params)}

    message = %{
      id: "m#{System.unique_integer([:positive])}",
      author: "You",
      initials: "YO",
      time: "now",
      ai: false,
      text: String.trim(body)
    }

    %{state | threads: add_message(threads, key, message, message.text)}
  end

  def reply(state, _params), do: state

  defp add_message(threads, _key, _message, ""), do: threads

  defp add_message(threads, key, message, _text) do
    Map.update(threads, key, %{resolved: false, messages: [message]}, fn thread ->
      %{thread | messages: thread.messages ++ [message]}
    end)
  end

  @doc "Applies the suggestion of a message: the line takes its new text and the suggestion is gone."
  def apply_suggestion(
        %{selected: path, threads: threads} = state,
        %{"line" => line, "message" => id} = params
      ) do
    key = {path, to_int(line), side(params)}
    thread = Map.get(threads, key, %{messages: []})
    message = Enum.find(thread.messages, &(&1.id == id and Map.has_key?(&1, :suggestion)))
    applied(state, key, thread, message)
  end

  def apply_suggestion(state, _params), do: state

  defp applied(state, _key, _thread, nil), do: state

  defp applied(%{selected: path} = state, key, thread, %{suggestion: suggestion} = message) do
    messages = Enum.map(thread.messages, &drop_suggestion(&1, message.id))

    hunks =
      Enum.map(hunks(state, path), fn hunk ->
        %{hunk | lines: Enum.map(hunk.lines, &replace_text(&1, suggestion))}
      end)

    %{
      state
      | files: Map.put(state.files, path, hunks),
        threads: Map.put(state.threads, key, %{thread | messages: messages})
    }
  end

  defp drop_suggestion(%{id: id} = message, id), do: Map.delete(message, :suggestion)
  defp drop_suggestion(message, _id), do: message

  defp replace_text(%{kind: :add, text: from} = line, %{from: from, to: to}),
    do: %{line | text: to}

  defp replace_text(line, _suggestion), do: line

  defp side(%{"side" => "old"}), do: :old
  defp side(_params), do: :new

  defp to_int(value) when is_integer(value), do: value
  defp to_int(value), do: String.to_integer(value)

  attr :path, :string, required: true
  attr :line, :integer, required: true
  attr :side, :atom, default: :new
  attr :thread, :map, required: true

  @doc "The conversation of a thread of the demo, as a `DiffView.line_thread`."
  def thread(assigns) do
    ~H"""
    <DiffView.line_thread
      id={"thread-#{@side}-#{@line}"}
      label={"Conversation on line #{@line}"}
      path={@path}
      line={@line}
      side={@side}
      resolved={@thread.resolved}
      placeholder="Reply… use @ to mention and ``` for code"
      reply_label="Reply"
      note="Markdown supported"
      resolve_label={(@thread.messages == [] && "Cancel") || "Resolve"}
      comment_label="Comment"
      suggestion_label="Suggested change"
      apply_label="Apply suggestion"
      resolve_event="resolve_thread"
      comment_event="reply_thread"
      apply_event="apply_suggestion"
    >
      <:message
        :for={message <- @thread.messages}
        id={message.id}
        author={message.author}
        initials={message.initials}
        time={message.time}
        ai_label={(message.ai && "AI") || nil}
        suggestion={Map.get(message, :suggestion)}
      >
        {message.text}
      </:message>
      <:summary>Thread resolved</:summary>
    </DiffView.line_thread>
    """
  end
end
