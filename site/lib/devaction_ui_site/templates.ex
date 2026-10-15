defmodule DevactionUISite.Templates do
  @moduledoc """
  The full-page templates of the documentation: whole screens built only from the library's components, grouped
  by what they are for (the sign-in screens, for one). Each is a page of its own at `/screens/<group>/<slug>`,
  drawn from `screens/<group>_<slug>.html.heex`, and the documentation shows it scaled down beside its code.
  """

  @groups [
    %{
      slug: "auth",
      title: "Auth",
      summary:
        "The sign-in screens of a product: one for each way in and for each step, in the library's own components.",
      screens: [
        %{
          slug: "login",
          title: "Sign in",
          text:
            "A social button, a switch between a magic link and a password, and the way to an account.",
          height: 920
        },
        %{
          slug: "signup",
          title: "Create account",
          text: "A name and an e-mail, or the social button, with the terms under them.",
          height: 920
        },
        %{
          slug: "link_sent",
          title: "Link sent",
          text:
            "What to do after asking for a link: open the mail, wait, try again; with a preview of the message.",
          height: 1060
        },
        %{
          slug: "keep_signed_in",
          title: "Keep me signed in",
          text: "Coming back through a link: stay signed in on this device or only this once.",
          height: 920
        },
        %{
          slug: "forgot_password",
          title: "Forgot password",
          text: "One field and a promise that no one is told whether the address exists.",
          height: 900
        },
        %{
          slug: "reset_password",
          title: "Reset password",
          text: "A new password with its meter and rules, and a confirmation.",
          height: 1000
        },
        %{
          slug: "account_security",
          title: "Account and security",
          text:
            "Inside the app: e-mail, password, the ways to sign in and the connected devices.",
          height: 1240
        }
      ]
    }
  ]

  @doc "The groups of templates."
  def groups, do: @groups

  @doc "A group by its slug."
  def fetch(slug) do
    case Enum.find(@groups, &(&1.slug == slug)) do
      nil -> :error
      group -> {:ok, group}
    end
  end

  @doc "A screen by its group and slug, with the group."
  def screen(group_slug, slug) do
    with {:ok, group} <- fetch(group_slug),
         screen when not is_nil(screen) <- Enum.find(group.screens, &(&1.slug == slug)) do
      {:ok, group, screen}
    else
      _missing -> :error
    end
  end

  @doc "The width every screen is drawn at before it is scaled to the page."
  def width, do: 1440
end
