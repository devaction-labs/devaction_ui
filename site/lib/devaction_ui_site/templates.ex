defmodule DevactionUISite.Templates do
  @moduledoc """
  The full-page templates of the documentation: whole screens built only from the library's components, grouped
  by what they are for (the sign-in screens, for one). Each is a page of its own at `/screens/<group>/<slug>`,
  drawn from `screens/<group>_<slug>.html.heex`, and the documentation shows it scaled down beside its code.
  """

  @width 1440

  @groups [
    %{
      slug: "auth",
      since: "0.1",
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
    },
    %{
      slug: "app",
      since: "0.3",
      title: "App",
      summary:
        "The frame of a working product: the sidebar, the header and the page of a list with its table.",
      screens: [
        %{
          slug: "projects",
          title: "Projects",
          text:
            "A workspace switcher and a search in the sidebar, the page head with its tabs and filters, and a table with the first column and the actions pinned, a progress cell and a menu on each row.",
          height: 900
        }
      ]
    },
    %{
      slug: "email",
      since: "0.4",
      width: 720,
      title: "Email",
      summary:
        "The transactional and product e-mails of an app: eleven messages built only from the e-mail components, as tables with inline styles, with a light and a dark preview.",
      screens: [
        %{
          slug: "magic_link",
          title: "Magic link",
          text:
            "Sign in with one click: a button, the address to copy, and a line that says when and where it was asked.",
          height: 603
        },
        %{
          slug: "confirm_account",
          title: "Confirm account",
          text: "A welcome with the three steps ahead and the button that confirms the e-mail.",
          height: 782
        },
        %{
          slug: "update_email",
          title: "Update e-mail",
          text:
            "The new address in a details table, a button, and the promise that the old one stays if it was not you.",
          height: 643
        },
        %{
          slug: "reset_password",
          title: "Reset password",
          text:
            "A button that works for one hour, a notice for who needs to sign in now, and the address to copy.",
          height: 681
        },
        %{
          slug: "password_changed",
          title: "Password changed",
          text:
            "What changed, when and where, a notice in risk tone and a secondary button to reset it again.",
          height: 676
        },
        %{
          slug: "new_device",
          title: "New device",
          text:
            "The details of a first access from a device and a secondary button for who does not recognize it.",
          height: 701
        },
        %{
          slug: "review_ready",
          title: "Review ready",
          text:
            "A pull request reviewed by the AI: the counts, the findings with their place, the button and a suggested lesson.",
          height: 940
        },
        %{
          slug: "contract_expiring",
          title: "Contract expiring",
          text: "A renewal in 30 days: the details of the contract and two buttons side by side.",
          height: 699
        },
        %{
          slug: "amendment_signature",
          title: "Amendment for signature",
          text:
            "Sent to the client with the agency's name: the new scope as a list, the new date and a button to sign.",
          height: 839
        },
        %{
          slug: "weekly_digest",
          title: "Weekly digest",
          text:
            "Three numbers, the next contract events with their tags, a suggested lesson and a button.",
          height: 955
        },
        %{
          slug: "workspace_invite",
          title: "Workspace invite",
          text: "Who invited you, the role in a chip and a button to accept.",
          height: 601
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

  @doc "The width every screen is drawn at before it is scaled to the page: the group's own, else 1440."
  def width(group), do: Map.get(group, :width, @width)
end
