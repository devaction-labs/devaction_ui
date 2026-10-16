defmodule DevactionUISite.ExampleLive do
  @moduledoc """
  One example of a component page as a LiveView of its own. Every example on the page is rendered inside the page
  with `live_render`, so each has its own process, its own demo data and its own events: typing in one
  autocomplete does not touch the next. The demo data is a made-up workspace (pull requests, a board, a calendar),
  and the events are the ones the examples send (`search`, `sort`, `move_card`, `calendar_next`...); an event the
  demo does not know is ignored.
  """
  use Phoenix.LiveView

  alias DevactionUISite.{ReviewDemo, TopicHTML}

  @forms_repos ~w(sge-api ayram-web hub-api)
  @overlays ~w(drawer_floating drawer_docked drawer_left drawer_wide modal_confirm modal_form modal_success modal_tall danger drawer_sheet drawer_stack confirm_locked)

  @rows [
    %{
      id: "142",
      title: "Dízimos em transação",
      author: "carlos-andre",
      changes: 187,
      status: "open"
    },
    %{
      id: "145",
      title: "Estornos e exportação CSV",
      author: "carlos-andre",
      changes: 120,
      status: "open"
    },
    %{
      id: "61",
      title: "Multi no checkout",
      author: "fernando-paiva",
      changes: 64,
      status: "merged"
    },
    %{id: "63", title: "Busca com filtros", author: "alex-nogueira", changes: 33, status: "open"}
  ]

  @board %{
    "todo" => [{"c1", "Envolver lançamento em Ecto.Multi"}, {"c2", "Revisar migration do caixa"}],
    "doing" => [{"c3", "Estorno de dízimo"}],
    "done" => [{"c4", "Importar planilha"}]
  }

  @notifications [
    %{
      id: "n1",
      day: "Today",
      type: "reviews",
      icon: "sparkles",
      tone: :warn,
      title: "The AI finished the review of #214: 2 blocking findings",
      meta: "sge-api · 4 min ago"
    },
    %{
      id: "n2",
      day: "Today",
      type: "mentions",
      icon: "@",
      tone: :info,
      title: "Carlos André mentioned you in \"Financial reports\"",
      meta: "SGE · M3 · 1 h ago"
    },
    %{
      id: "n3",
      day: "Today",
      type: "other",
      icon: "contracts",
      tone: :risk,
      title: "The AYRAM contract renews in 3 days with no proposal sent",
      meta: "Contracts · 3 h ago"
    },
    %{
      id: "n4",
      day: "Yesterday",
      type: "reviews",
      icon: "checkmark-circle-02",
      tone: :ok,
      old: true,
      title: "Hub API #88 approved by the AI, ready to merge",
      meta: "hub-api · yesterday 17:40"
    },
    %{
      id: "n5",
      day: "Yesterday",
      type: "mentions",
      icon: "user",
      tone: :neutral,
      old: true,
      title: "Fernando assigned \"Schedule and shifts\" to you",
      meta: "SGE · M4 · yesterday 10:12"
    }
  ]

  @queue [
    %{ref: "1", name: "Contract SGE · Addendum 02.pdf", size: 1_800_000, state: :sent},
    %{
      ref: "2",
      name: "M3 reports specification.pdf",
      size: 6_100_000,
      state: :uploading,
      progress: 64
    },
    %{
      ref: "3",
      name: "finance-screenshot.png",
      size: 3_400_000,
      state: :failed,
      progress: 38,
      message: "Connection dropped"
    },
    %{ref: "4", name: "Meeting minutes 10-14.pdf", size: 420_000, state: :queued},
    %{ref: "5", name: "hours-sheet.xlsx", size: 88_000, state: :rejected}
  ]

  @otp_states %{
    "empty" => %{state: "empty", value: "", status: :idle, helper: "6 digits"},
    "typing" => %{state: "typing", value: "482", status: :idle, helper: "3 digits to go"},
    "error" => %{
      state: "error",
      value: "482913",
      status: :error,
      helper: "Wrong code. 2 tries left."
    },
    "ok" => %{state: "ok", value: "482913", status: :ok, helper: "Verified. Signing in…"}
  }
  @milestones %{
    "m1" => {"M1", "Member registry", "delivered"},
    "m2" => {"M2", "Tithes and offerings", "delivered"},
    "m3" => {"M3", "Financial reports", "Oct 16"},
    "m4" => {"M4", "Schedules and shifts", "Nov 20"},
    "m5" => {"M5", "Members app", "Dec 18"}
  }
  @milestone_order ~w(m1 m2 m3 m4 m5)
  @panes %{"nav" => 20.0, "main" => 55.0, "side" => 25.0}

  @impl true
  def mount(_params, %{"example" => example}, socket) do
    {:ok,
     assign(socket,
       example_id: example,
       review: ReviewDemo.state(),
       rows: @rows,
       sort: nil,
       board: @board,
       q: "",
       groups: [],
       toasts: [],
       toast_seq: 0,
       job: nil,
       order: "deadline",
       pdf: pdf_state(pdf_start(example), 100, false),
       queue: @queue,
       otp: @otp_states["typing"],
       otp_form: %{value: "", status: :idle, helper: "Try 482913"},
       range_applied: nil,
       times: %{start: "09:00", stop: "11:15"},
       editor: %{
         markdown: "",
         sent: nil,
         slash: [
           %{key: "h2", label: "Heading 2"},
           %{key: "h3", label: "Heading 3"},
           %{key: "bulletList", label: "Bulleted list"},
           %{key: "taskList", label: "Task list"},
           %{key: "blockquote", label: "Quote"},
           %{key: "codeBlock", label: "Code block"}
         ],
         members: [
           %{id: "u1", label: "Maria Souza"},
           %{id: "u2", label: "Alex Nogueira"},
           %{id: "u3", label: "Marcos Lima"}
         ]
       },
       calendar: %{
         date: ~D[2026-10-15],
         view: :month,
         selected: nil,
         events: [
           %{id: "e1", date: ~D[2026-10-02], label: "M1 delivered", kind: :ok},
           %{id: "e2", date: ~D[2026-10-15], label: "M3 · Finance", kind: :warn},
           %{id: "e3", date: ~D[2026-10-15], label: "Invoice 3", kind: :info},
           %{id: "e4", date: ~D[2026-10-15], label: "Amendment 01", kind: :neutral},
           %{id: "e5", date: ~D[2026-10-15], label: "Client review", kind: :risk},
           %{id: "e6", date: ~D[2026-10-23], label: "M3 new deadline", kind: :risk}
         ]
       },
       inputs: %{
         seats: 2,
         rate: 0.5,
         area: 12.5,
         hours: 12,
         hours_format: 24,
         hours_ticks: 20,
         from: 20,
         to: 70,
         timer_base: 0,
         timer_started: nil,
         logged: nil,
         sign_mode: :draw
       },
       shell: %{
         view: "list",
         layout: "rows",
         status: "open",
         collapsed: false,
         palette: false,
         query: "",
         scope: "all"
       },
       charts_table?: false,
       stepper: %{current: 2, error: nil},
       forms: %{
         show_password: false,
         repo: "devaction-labs/sge-api",
         scope: "The billing screen: entries, refunds and the monthly report.",
         checked: ["sge-api"],
         model: "fixed",
         publish: "draft"
       },
       notifications: notifications(%{tab: "all", read: []}),
       pricing: %{period: "yearly", chosen: nil},
       cookies: %{open: false, analytics: false, marketing: false, answered: nil},
       overlays: %{kind: nil, typed: "", done: false, nested: false},
       secret_revealed: false,
       banners_dismissed: [],
       menus: %{picked: nil},
       suggest: %{mode: "mention", active: 0},
       sortable: %{items: @milestones, order: @milestone_order, last: nil},
       resizable: %{sizes: @panes},
       switches: %{on: ["auto_review", "card_ai", "repo-sge-api"], saving: nil, saved: false},
       confirming: false,
       published: false,
       messages: [{:ai, "I made the task from the review of #142. Open a branch?"}]
     )
     |> allow_upload(:transcript,
       accept: ~w(audio/* .txt),
       max_entries: 1,
       max_file_size: 200_000_000
     )}
  end

  @impl true
  def render(assigns), do: TopicHTML.render(assigns.example_id, assigns)

  @impl true
  def handle_event("sort", %{"key" => key}, socket) do
    sort =
      case socket.assigns.sort do
        {^key, :asc} -> {key, :desc}
        _other -> {key, :asc}
      end

    {:noreply, assign(socket, sort: sort, rows: sort_rows(@rows, sort))}
  end

  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, assign(socket, q: q, groups: search(q))}
  end

  def handle_event("ask", %{"q" => q}, socket),
    do: {:noreply, push_toast(socket, :light, "Asked the AI: #{q}")}

  def handle_event("forms_toggle_password", _params, socket),
    do:
      {:noreply,
       update_forms(socket, &Map.update!(&1, :show_password, fn shown -> not shown end))}

  def handle_event("forms_repo", %{"value" => repo}, socket),
    do: {:noreply, update_forms(socket, &Map.put(&1, :repo, repo))}

  def handle_event("forms_clear_repo", _params, socket),
    do: {:noreply, update_forms(socket, &Map.put(&1, :repo, ""))}

  def handle_event("forms_scope", %{"value" => scope}, socket),
    do: {:noreply, update_forms(socket, &Map.put(&1, :scope, scope))}

  def handle_event("forms_all", _params, socket) do
    {:noreply, update_forms(socket, &Map.put(&1, :checked, all_or_none(length(&1.checked))))}
  end

  def handle_event("forms_repo_toggle", %{"id" => repo}, socket) when repo in @forms_repos do
    {:noreply,
     update_forms(socket, &Map.update!(&1, :checked, fn checked -> toggle(checked, repo) end))}
  end

  def handle_event("forms_repo_toggle", _params, socket), do: {:noreply, socket}

  def handle_event("forms_model", %{"choice" => model}, socket),
    do: {:noreply, update_forms(socket, &Map.put(&1, :model, model))}

  def handle_event("forms_publish", %{"choice" => publish}, socket),
    do: {:noreply, update_forms(socket, &Map.put(&1, :publish, publish))}

  def handle_event("overlay_open", %{"kind" => kind}, socket) when kind in @overlays,
    do:
      {:noreply, assign(socket, :overlays, %{kind: kind, typed: "", done: false, nested: false})}

  def handle_event("overlay_open", _params, socket), do: {:noreply, socket}

  def handle_event("overlay_close", _params, socket),
    do: {:noreply, update(socket, :overlays, &%{&1 | kind: nil, typed: "", nested: false})}

  def handle_event("overlay_nested", _params, socket),
    do: {:noreply, update(socket, :overlays, &%{&1 | nested: true})}

  def handle_event("overlay_unnest", _params, socket),
    do: {:noreply, update(socket, :overlays, &%{&1 | nested: false})}

  def handle_event("overlay_type", %{"value" => typed}, socket),
    do: {:noreply, update(socket, :overlays, &%{&1 | typed: typed})}

  def handle_event("overlay_confirm", _params, %{assigns: %{overlays: %{typed: typed}}} = socket) do
    {:noreply, confirm(socket, DevactionUI.DangerDialog.confirmed?(typed, "sge-api"))}
  end

  def handle_event("overlay_undo", _params, socket),
    do: {:noreply, update(socket, :overlays, &%{&1 | done: false})}

  def handle_event("charts_table", _params, socket),
    do: {:noreply, update(socket, :charts_table?, &(not &1))}

  def handle_event("stepper_next", _params, socket),
    do: {:noreply, update(socket, :stepper, &%{current: min(&1.current + 1, 5), error: nil})}

  def handle_event("stepper_prev", _params, socket),
    do: {:noreply, update(socket, :stepper, &%{current: max(&1.current - 1, 1), error: nil})}

  def handle_event("stepper_fail", _params, socket),
    do: {:noreply, update(socket, :stepper, &%{&1 | error: &1.current})}

  def handle_event("stepper_reset", _params, socket),
    do: {:noreply, assign(socket, :stepper, %{current: 1, error: nil})}

  def handle_event("switch_toggle", %{"key" => key}, socket) do
    Process.send_after(self(), {:switch_saved, key}, 300)
    {:noreply, update(socket, :switches, &%{&1 | saving: key, saved: false})}
  end

  def handle_event("seats_step", %{"step" => step}, socket) do
    {:noreply,
     update_inputs(
       socket,
       &Map.update!(&1, :seats, fn seats -> DevactionUI.NumberInput.step(seats, step, 1, 5) end)
     )}
  end

  def handle_event("area_step", %{"step" => step}, socket) do
    {:noreply,
     update_inputs(
       socket,
       &Map.update!(&1, :area, fn area -> DevactionUI.NumberInput.step(area, step, 0, 100) end)
     )}
  end

  def handle_event("rate_step", %{"step" => step}, socket) do
    {:noreply,
     update_inputs(
       socket,
       &Map.update!(&1, :rate, fn rate -> DevactionUI.NumberInput.step(rate, step, 0, 2) end)
     )}
  end

  def handle_event("inputs_change", params, socket) do
    {low, high} =
      DevactionUI.Slider.range(0, 100, {to_int(params["from"], 20), to_int(params["to"], 70)})

    {:noreply,
     update_inputs(
       socket,
       &%{
         &1
         | hours: to_int(params["hours"], &1.hours),
           hours_format: to_int(params["hours_format"], &1.hours_format),
           hours_ticks: to_int(params["hours_ticks"], &1.hours_ticks),
           from: low,
           to: high
       }
     )}
  end

  def handle_event("slider_hours", params, socket),
    do: handle_event("inputs_change", params, socket)

  def handle_event("timer_toggle", _params, %{assigns: %{inputs: inputs}} = socket) do
    now = System.os_time(:second)

    inputs =
      case inputs.timer_started do
        nil ->
          %{inputs | timer_started: now, logged: nil}

        started ->
          %{
            inputs
            | timer_base: DevactionUI.Timer.elapsed(inputs.timer_base, started, now),
              timer_started: nil
          }
      end

    {:noreply, assign(socket, :inputs, inputs)}
  end

  def handle_event("timer_log", _params, %{assigns: %{inputs: inputs}} = socket) do
    seconds =
      DevactionUI.Timer.elapsed(inputs.timer_base, inputs.timer_started, System.os_time(:second))

    {:noreply,
     assign(socket, :inputs, %{inputs | timer_base: 0, timer_started: nil, logged: seconds})}
  end

  def handle_event("sign_mode", %{"mode" => mode}, socket) when mode in ["draw", "type"],
    do: {:noreply, update_inputs(socket, &%{&1 | sign_mode: String.to_existing_atom(mode)})}

  def handle_event("sign_mode", _params, socket), do: {:noreply, socket}

  def handle_event("shell_view", %{"value" => value}, socket)
      when value in ["list", "board", "calendar"],
      do: {:noreply, update_shell(socket, view: value)}

  def handle_event("shell_layout", %{"value" => value}, socket)
      when value in ["rows", "cards"],
      do: {:noreply, update_shell(socket, layout: value)}

  def handle_event("shell_status", %{"value" => value}, socket)
      when value in ["open", "done"],
      do: {:noreply, update_shell(socket, status: value)}

  def handle_event("shell_collapse", _params, socket),
    do: {:noreply, update_shell(socket, collapsed: not socket.assigns.shell.collapsed)}

  def handle_event("palette_open", _params, socket),
    do: {:noreply, update_shell(socket, palette: true, query: "", scope: "all")}

  def handle_event("palette_close", _params, socket),
    do: {:noreply, socket |> update_shell(palette: false, query: "") |> assign(:groups, [])}

  def handle_event("palette_search", %{"query" => query}, socket),
    do: {:noreply, socket |> update_shell(query: query) |> assign(:groups, search(query))}

  def handle_event("palette_scope", %{"value" => scope}, socket)
      when scope in ["all", "prs", "lessons"],
      do: {:noreply, update_shell(socket, scope: scope)}

  def handle_event("shell_" <> _unknown, _params, socket), do: {:noreply, socket}

  def handle_event("palette_scope", _params, socket), do: {:noreply, socket}

  def handle_event("editor_change", %{"note" => %{"markdown" => markdown}}, socket),
    do: {:noreply, update(socket, :editor, &%{&1 | markdown: markdown})}

  def handle_event("comment_send", %{"comment" => %{"markdown" => markdown}}, socket),
    do: {:noreply, update(socket, :editor, &%{&1 | sent: markdown})}

  def handle_event("comment_send", _params, socket), do: {:noreply, socket}

  def handle_event("editor_change", _params, socket), do: {:noreply, socket}

  def handle_event("calendar_view", %{"value" => view}, socket) when view in ["month", "week"],
    do: {:noreply, update_calendar(socket, view: String.to_existing_atom(view))}

  def handle_event("calendar_select", %{"date" => date}, socket) do
    case Date.from_iso8601(date) do
      {:ok, day} -> {:noreply, update_calendar(socket, selected: day, date: day)}
      {:error, _reason} -> {:noreply, socket}
    end
  end

  def handle_event("calendar_prev", _params, socket), do: {:noreply, move_calendar(socket, -1)}
  def handle_event("calendar_next", _params, socket), do: {:noreply, move_calendar(socket, 1)}
  def handle_event("calendar_view", _params, socket), do: {:noreply, socket}

  def handle_event("order", %{"choice" => order}, socket),
    do: {:noreply, assign(socket, :order, order)}

  def handle_event("confirm_open", _params, socket),
    do: {:noreply, assign(socket, confirming: true, published: false)}

  def handle_event("confirm_cancel", _params, socket),
    do: {:noreply, assign(socket, :confirming, false)}

  def handle_event("confirm_publish", _params, socket),
    do: {:noreply, assign(socket, confirming: false, published: true)}

  def handle_event("prompt", %{"prompt" => text}, socket) do
    messages = socket.assigns.messages ++ [{:me, text}, {:ai, "Done: #{text}"}]
    {:noreply, assign(socket, :messages, messages)}
  end

  def handle_event("add_toast", _params, socket),
    do: {:noreply, push_toast(socket, :dark, "Review published")}

  def handle_event("run_job", _params, socket) do
    Process.send_after(self(), :job_tick, 300)
    {:noreply, assign(socket, :job, %{state: :running, progress: 0})}
  end

  def handle_event("dismiss_job", _params, socket), do: {:noreply, assign(socket, :job, nil)}

  def handle_event("dismiss_toast", %{"id" => id}, socket),
    do: {:noreply, assign(socket, :toasts, Enum.reject(socket.assigns.toasts, &(&1.id == id)))}

  def handle_event("clear_toasts", _params, socket), do: {:noreply, assign(socket, :toasts, [])}

  def handle_event("move_card", %{"card" => id, "to" => to, "index" => index}, socket) do
    {:noreply, assign(socket, :board, move(socket.assigns.board, id, to, index))}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket),
    do: {:noreply, cancel_upload(socket, :transcript, ref)}

  def handle_event("pdf_page", %{"page" => page}, %{assigns: %{pdf: pdf}} = socket),
    do: {:noreply, assign(socket, :pdf, pdf_state(whole(page, pdf.page), pdf.zoom, pdf.signed))}

  def handle_event("pdf_zoom", %{"zoom" => zoom}, %{assigns: %{pdf: pdf}} = socket),
    do: {:noreply, assign(socket, :pdf, pdf_state(pdf.page, whole(zoom, pdf.zoom), pdf.signed))}

  def handle_event("pdf_jump", _params, %{assigns: %{pdf: pdf}} = socket),
    do: {:noreply, assign(socket, :pdf, pdf_state(4, pdf.zoom, pdf.signed))}

  def handle_event("pdf_sign", %{"signer" => "Alex" <> _rest}, %{assigns: %{pdf: pdf}} = socket),
    do: {:noreply, assign(socket, :pdf, pdf_state(pdf.page, pdf.zoom, true))}

  def handle_event("pdf_sign", _params, socket), do: {:noreply, socket}

  def handle_event("secret_toggle", _params, socket),
    do: {:noreply, update(socket, :secret_revealed, &(not &1))}

  def handle_event("banner_dismiss", %{"tone" => tone}, socket)
      when tone in ~w(info warning critical offline),
      do: {:noreply, update(socket, :banners_dismissed, &[tone | &1])}

  def handle_event("banner_reset", _params, socket),
    do: {:noreply, assign(socket, :banners_dismissed, [])}

  def handle_event("notif_tab", %{"id" => tab}, %{assigns: %{notifications: current}} = socket)
      when tab in ["all", "mentions", "reviews"],
      do: {:noreply, assign(socket, :notifications, notifications(%{current | tab: tab}))}

  def handle_event("notif_open", %{"id" => id}, %{assigns: %{notifications: current}} = socket),
    do: {:noreply, assign(socket, :notifications, notifications(read(current, [id])))}

  def handle_event("notif_read_all", _params, %{assigns: %{notifications: current}} = socket),
    do:
      {:noreply,
       assign(
         socket,
         :notifications,
         notifications(read(current, Enum.map(@notifications, & &1.id)))
       )}

  def handle_event("pricing_period", %{"value" => period}, socket)
      when period in ["monthly", "yearly"],
      do: {:noreply, update(socket, :pricing, &%{&1 | period: period})}

  def handle_event("pricing_choose", %{"plan" => plan}, socket),
    do: {:noreply, update(socket, :pricing, &%{&1 | chosen: plan})}

  def handle_event("cookies_prefs", _params, socket),
    do: {:noreply, update(socket, :cookies, &%{&1 | open: !&1.open})}

  def handle_event("cookies_category", %{"id" => id}, socket)
      when id in ["analytics", "marketing"] do
    key = String.to_existing_atom(id)
    {:noreply, update(socket, :cookies, &Map.update!(&1, key, fn on -> !on end))}
  end

  def handle_event("cookies_necessary", _params, socket),
    do: {:noreply, assign(socket, :cookies, answered(false, "necessary"))}

  def handle_event("cookies_accept", _params, socket),
    do: {:noreply, assign(socket, :cookies, answered(true, "all"))}

  def handle_event("select_file", params, socket),
    do: {:noreply, update(socket, :review, &ReviewDemo.select(&1, params))}

  def handle_event("toggle_folder", params, socket),
    do: {:noreply, update(socket, :review, &ReviewDemo.toggle(&1, params))}

  def handle_event("filter_files", params, socket),
    do: {:noreply, update(socket, :review, &ReviewDemo.filter(&1, params))}

  def handle_event("search_files", params, socket),
    do: {:noreply, update(socket, :review, &ReviewDemo.search(&1, params))}

  def handle_event("toggle_viewed", params, socket),
    do: {:noreply, update(socket, :review, &ReviewDemo.view(&1, params))}

  def handle_event("comment_line", params, socket),
    do: {:noreply, update(socket, :review, &ReviewDemo.comment(&1, params))}

  def handle_event("resolve_thread", params, socket),
    do: {:noreply, update(socket, :review, &ReviewDemo.resolve(&1, params))}

  def handle_event("reply_thread", params, socket),
    do: {:noreply, update(socket, :review, &ReviewDemo.reply(&1, params))}

  def handle_event("apply_suggestion", params, socket),
    do: {:noreply, update(socket, :review, &ReviewDemo.apply_suggestion(&1, params))}

  def handle_event("queue_retry", %{"ref" => ref}, socket),
    do: {:noreply, update(socket, :queue, &Enum.map(&1, fn row -> retry_row(row, ref) end))}

  def handle_event("queue_cancel", %{"ref" => ref}, socket),
    do: {:noreply, update(socket, :queue, &Enum.reject(&1, fn row -> row.ref == ref end))}

  def handle_event("queue_clear", _params, socket),
    do: {:noreply, update(socket, :queue, &Enum.reject(&1, fn row -> row.state == :sent end))}

  def handle_event("otp_state", %{"value" => state}, socket) when is_map_key(@otp_states, state),
    do: {:noreply, assign(socket, :otp, Map.fetch!(@otp_states, state))}

  def handle_event("otp_check", %{"code" => code}, socket),
    do: {:noreply, assign(socket, :otp_form, check_code(code))}

  def handle_event("range_change", %{"period_from" => from, "period_to" => to}, socket),
    do: {:noreply, assign(socket, :range_applied, {from, to})}

  def handle_event("time_change", %{"entry" => %{"start" => start, "end" => stop}}, socket),
    do: {:noreply, assign(socket, :times, %{start: start, stop: stop})}

  def handle_event("context_pick", %{"choice" => choice}, socket),
    do: {:noreply, update(socket, :menus, &%{&1 | picked: choice})}

  def handle_event("suggest_mode", %{"value" => mode}, socket) when mode in ["mention", "slash"],
    do: {:noreply, update(socket, :suggest, &%{&1 | mode: mode})}

  def handle_event("suggest_pick", %{"choice" => choice}, socket) do
    case Integer.parse(choice) do
      {index, ""} when index in 0..3 ->
        {:noreply, update(socket, :suggest, &%{&1 | active: index})}

      _other ->
        {:noreply, socket}
    end
  end

  def handle_event(
        "reorder",
        %{"order" => order} = params,
        %{assigns: %{sortable: sortable}} = socket
      )
      when is_list(order) do
    case Enum.sort(order) == Enum.sort(sortable.order) do
      true ->
        last = %{id: params["id"], from: params["from"], to: params["to"]}
        {:noreply, assign(socket, :sortable, %{sortable | order: order, last: last})}

      false ->
        {:noreply, socket}
    end
  end

  def handle_event("sortable_sort", _params, socket),
    do: {:noreply, update(socket, :sortable, &%{&1 | order: @milestone_order, last: nil})}

  def handle_event("sortable_reverse", _params, socket),
    do: {:noreply, update(socket, :sortable, &%{&1 | order: Enum.reverse(&1.order), last: nil})}

  def handle_event("resize", %{"sizes" => sizes}, socket) when is_map(sizes) do
    known = Map.take(sizes, Map.keys(@panes))

    case Enum.all?(known, fn {_id, size} -> is_number(size) end) and
           map_size(known) == map_size(@panes) do
      true -> {:noreply, update(socket, :resizable, &%{&1 | sizes: known})}
      false -> {:noreply, socket}
    end
  end

  def handle_event("resizable_reset", _params, socket),
    do: {:noreply, update(socket, :resizable, &%{&1 | sizes: @panes})}

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  @lessons [
    {"30", "Ecto.Multi e rollback", :warn},
    {"62", "Ecto changesets aninhados", :info},
    {"11", "LiveView streams", :info}
  ]
  @prs [
    {"142", "Dízimos com Ecto.Multi"},
    {"61", "Multi no checkout"},
    {"145", "Estornos de dízimo"}
  ]

  defp pdf_start("pdf_viewer_05"), do: 1
  defp pdf_start(_example), do: 4

  defp whole(value, fallback) do
    case Integer.parse(to_string(value)) do
      {number, ""} -> number
      _other -> fallback
    end
  end

  defp pdf_state(page, zoom, signed) do
    %{
      page: DevactionUI.PdfViewer.clamp_page(page, 4),
      zoom: zoom |> max(50) |> min(300),
      signed: signed,
      fields: [
        %{
          page: 4,
          x: 8,
          y: 80.6,
          w: 38.6,
          h: 10.4,
          signer: "Responsible · Campo Limpo Church",
          state: :signed,
          label: "Signed"
        },
        %{
          page: 4,
          x: 53.3,
          y: 80.6,
          w: 38.6,
          h: 10.4,
          signer: "Alex · DevAction Labs",
          state: pdf_mine(signed),
          label: pdf_mine_label(signed)
        }
      ],
      signers: [
        %{
          name: "Church Admin",
          role: "Campo Limpo Church",
          status: :signed,
          status_label: "Signed",
          tone: :red
        },
        %{
          name: "Alex",
          role: "DevAction Labs",
          status: pdf_status(signed),
          status_label: pdf_status_label(signed),
          mine: true
        }
      ]
    }
  end

  defp pdf_mine(true), do: :signed
  defp pdf_mine(false), do: :mine
  defp pdf_mine_label(true), do: "Signed"
  defp pdf_mine_label(false), do: "Sign"
  defp pdf_status(true), do: :signed
  defp pdf_status(false), do: :pending
  defp pdf_status_label(true), do: "Signed"
  defp pdf_status_label(false), do: "Pending"

  defp search(""), do: []

  defp search(q) do
    needle = fold(q)

    lessons =
      for {hint, label, tone} <- @lessons,
          String.contains?(fold(label), needle),
          do: %{id: "l#{hint}", label: label, to: "/dev/ui", hint: hint, tone: tone}

    prs =
      for {number, label} <- @prs,
          String.contains?(fold(label), needle),
          do: %{id: "p#{number}", label: label, to: "/dev/ui", hint: "##{number}", tone: :risk}

    Enum.reject(
      [%{label: "Lessons", items: lessons}, %{label: "Pull requests", items: prs}],
      &(&1.items == [])
    )
  end

  defp fold(text),
    do: text |> String.normalize(:nfd) |> String.replace(~r/\p{Mn}/u, "") |> String.downcase()

  @impl true
  def handle_info(:job_tick, %{assigns: %{job: %{state: :running, progress: progress}}} = socket) do
    next = min(progress + 20, 100)
    schedule(next)
    {:noreply, assign(socket, :job, %{state: job_state(next), progress: next})}
  end

  def handle_info(:job_tick, socket), do: {:noreply, socket}

  def handle_info({:switch_saved, key}, socket) do
    {:noreply,
     update(socket, :switches, fn switches ->
       %{switches | on: toggle(switches.on, key), saving: nil, saved: true}
     end)}
  end

  defp all_or_none(3), do: []
  defp all_or_none(_count), do: @forms_repos

  defp toggle(list, item), do: toggle(list, item, item in list)
  defp toggle(list, item, true), do: List.delete(list, item)
  defp toggle(list, item, false), do: [item | list]

  defp confirm(socket, true),
    do: assign(socket, :overlays, %{kind: nil, typed: "", done: true, nested: false})

  defp confirm(socket, false), do: socket

  defp job_state(100), do: :done
  defp job_state(_progress), do: :running

  defp schedule(100), do: :ok
  defp schedule(_progress), do: Process.send_after(self(), :job_tick, 300)

  defp update_inputs(socket, fun), do: update(socket, :inputs, fun)

  defp to_int(text, default) do
    case Integer.parse(to_string(text)) do
      {number, _rest} -> number
      :error -> default
    end
  end

  defp answered(on, answer),
    do: %{open: false, analytics: on, marketing: on, answered: answer}

  defp read(%{read: read} = current, ids), do: %{current | read: Enum.uniq(read ++ ids)}

  defp notifications(%{tab: tab, read: read}) do
    visible = Enum.filter(@notifications, &(tab == "all" or &1.type == tab))

    unread = fn type ->
      Enum.count(@notifications, &(not read?(&1, read) and match_type?(&1, type)))
    end

    %{
      tab: tab,
      read: read,
      tabs: [
        %{id: "all", label: "All", count: unread.("all")},
        %{id: "mentions", label: "Mentions", count: unread.("mentions")},
        %{id: "reviews", label: "Reviews", count: unread.("reviews")}
      ],
      groups:
        for day <- visible |> Enum.map(& &1.day) |> Enum.uniq() do
          %{
            id: String.downcase(day),
            label: String.upcase(day),
            items:
              for item <- visible, item.day == day do
                Map.put(item, :unread, not read?(item, read))
              end
          }
        end
    }
  end

  defp read?(%{old: true}, _read), do: true
  defp read?(%{id: id}, read), do: id in read

  defp match_type?(_item, "all"), do: true
  defp match_type?(%{type: type}, type), do: true
  defp match_type?(_item, _type), do: false

  defp retry_row(%{ref: ref, state: :failed} = row, ref),
    do: %{row | state: :uploading, progress: 12}

  defp retry_row(row, _ref), do: row

  defp check_code("482913"), do: %{value: "482913", status: :ok, helper: "Verified. Signing in…"}

  defp check_code(code) when byte_size(code) == 6,
    do: %{value: code, status: :error, helper: "Wrong code. Try 482913."}

  defp check_code(code), do: %{value: code, status: :idle, helper: "Try 482913"}

  defp update_shell(socket, changes),
    do: update(socket, :shell, &Map.merge(&1, Map.new(changes)))

  defp update_calendar(socket, changes),
    do: update(socket, :calendar, &Map.merge(&1, Map.new(changes)))

  defp move_calendar(%{assigns: %{calendar: %{view: :month, date: date}}} = socket, delta),
    do: update_calendar(socket, date: DevactionUI.Calendar.shift_month(date, delta))

  defp move_calendar(%{assigns: %{calendar: %{view: :week, date: date}}} = socket, delta),
    do: update_calendar(socket, date: Date.add(date, delta * 7))

  defp update_forms(socket, fun), do: update(socket, :forms, fun)

  defp push_toast(socket, kind, title) do
    seq = socket.assigns.toast_seq + 1
    toast = %{id: "toast-#{seq}", kind: kind, title: title}
    assign(socket, toasts: [toast | socket.assigns.toasts], toast_seq: seq)
  end

  defp sort_rows(rows, {key, direction}) do
    field = String.to_existing_atom(key)
    Enum.sort_by(rows, &Map.fetch!(&1, field), direction)
  end

  defp move(board, id, to, index) do
    {card, rest} =
      Enum.reduce(board, {nil, %{}}, fn {column, cards}, {found, acc} ->
        {hit, others} = Enum.split_with(cards, &(elem(&1, 0) == id))
        {found || List.first(hit), Map.put(acc, column, others)}
      end)

    Map.update!(rest, to, &List.insert_at(&1, index, card))
  end
end
