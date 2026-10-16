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
        Banner,
        Breadcrumb,
        Button,
        Calendar,
        Chart,
        ChatBubble,
        Choice,
        ColorPicker,
        Combobox,
        CommandPalette,
        Composer,
        ConfirmDialog,
        ContextMenu,
        CookieConsent,
        CopyField,
        DangerDialog,
        DataTable,
        DatePicker,
        DateRange,
        DescriptionList,
        DiffView,
        Divider,
        Drawer,
        Dropdown,
        Dropzone,
        Editor,
        EmptyState,
        Field,
        FileTree,
        FilterMenu,
        FilterPill,
        HoverCard,
        InputGroup,
        Kanban,
        Modal,
        MoneyInput,
        NotificationCenter,
        NumberInput,
        OtpInput,
        PageHeader,
        Pagination,
        PasswordStrength,
        PdfViewer,
        Pillbox,
        Popover,
        Pricing,
        Progress,
        ProgressToast,
        Resizable,
        RowMenu,
        ScrollArea,
        Segmented,
        Separator,
        Shell,
        Sidebar,
        SignatureField,
        Slider,
        SortableList,
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
