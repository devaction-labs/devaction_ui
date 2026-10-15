defmodule DevactionUISite.Layouts do
  @moduledoc "The document around every page: styles, the theme script and the LiveView script."
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <.live_title default="DevactionUI">{assigns[:page_title]}</.live_title>
        <link rel="stylesheet" href="/assets/css/site.css" />
        <script src="/assets/js/theme.js">
        </script>
        <script defer src="/assets/js/app.js">
        </script>
      </head>
      <body class="bg-frame text-ink antialiased">
        {@inner_content}
      </body>
    </html>
    """
  end
end
