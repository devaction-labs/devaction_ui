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
        DateRange,
        Divider,
        Drawer,
        Dropdown,
        Dropzone,
        Editor,
        EmptyState,
        FilterMenu,
        FilterPill,
        InputGroup,
        Kanban,
        Modal,
        MoneyInput,
        NumberInput,
        OtpInput,
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
        TimeField,
        Timeline,
        Timer,
        ToastGroup,
        Tooltip
      }
    end
  end
end
