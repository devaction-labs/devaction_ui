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
        ContextMenu,
        DangerDialog,
        DataTable,
        DatePicker,
        Divider,
        Drawer,
        Dropdown,
        Dropzone,
        Editor,
        EmptyState,
        FilterMenu,
        FilterPill,
        HoverCard,
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
        Resizable,
        Segmented,
        Sidebar,
        SignatureField,
        Slider,
        SortableList,
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
