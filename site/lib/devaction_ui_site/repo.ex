defmodule DevactionUISite.Repo do
  @moduledoc """
  The SQLite database of the documentation site: the changelog lives here. The file is `DATABASE_PATH` in
  production (a volume keeps it between deploys), and the migrations run when the application starts.
  """
  use Ecto.Repo, otp_app: :devaction_ui_site, adapter: Ecto.Adapters.SQLite3
end
