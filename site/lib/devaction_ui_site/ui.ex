defmodule DevactionUISite.UI do
  @moduledoc """
  What every template of the site sees: the function components of the library imported or aliased by their short
  name, the icon component, and `JS`. Examples and screens `use` this instead of repeating the list.
  """

  defmacro __using__(_options) do
    quote do
      use Phoenix.Component

      import DevactionUI.{Callout, CodeBlock, Kbd, Panel, Progress, Skeleton, Spinner, Tag}
      import DevactionUISite.Icon

      alias DevactionUI.Textarea
      alias DevactionUISite.ReviewDemo
      alias Phoenix.LiveView.JS

      alias DevactionUI.{
        Accordion,
        AiPrompt,
        Alert,
        Aura,
        AuthCard,
        AuthLayout,
        Autocomplete,
        Avatar,
        Badge,
        Breadcrumb,
        Button,
        Calendar,
        Chart,
        ChatBubble,
        Choice,
        ColorPicker,
        Combobox,
        CommandPalette,
        ConfirmDialog,
        DangerDialog,
        DataTable,
        DatePicker,
        DiffView,
        Divider,
        Drawer,
        Dropdown,
        Dropzone,
        Editor,
        EmptyState,
        FileTree,
        FilterMenu,
        FilterPill,
        InputGroup,
        Kanban,
        Modal,
        MoneyInput,
        NumberInput,
        PageHeader,
        Pagination,
        PasswordStrength,
        Pillbox,
        Popover,
        Progress,
        ProgressToast,
        Segmented,
        Sidebar,
        SignatureField,
        Slider,
        Stat,
        Stepper,
        Steps,
        Switch,
        Tabs,
        Timeline,
        Timer,
        ToastGroup,
        Tooltip
      }
    end
  end
end
