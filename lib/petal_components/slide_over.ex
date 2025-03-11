defmodule PetalComponents.SlideOver do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr :id, :string, default: "slide-over"

  attr(:origin, :string,
    default: "right",
    values: ["left", "right", "top", "bottom"],
    doc: "slideover point of origin"
  )

  attr(:close_slide_over_target, :string,
    default: nil,
    doc:
      "close_slide_over_target allows you to target a specific live component for the close event to go to. eg: close_slide_over_target={@myself}"
  )

  attr(:close_on_click_away, :boolean,
    default: true,
    doc: "whether the slideover should close when a user clicks away"
  )

  attr(:close_on_escape, :boolean,
    default: true,
    doc: "whether the slideover should close when a user hits escape"
  )

  attr(:title, :string, default: nil, doc: "slideover title")

  attr(:max_width, :string,
    default: "md",
    values: ["sm", "md", "lg", "xl", "2xl", "full"],
    doc: "sets container max-width"
  )

  attr(:class, :any, default: nil, doc: "CSS class")
  attr(:hide, :boolean, default: false, doc: "slideover is hidden")
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def slide_over(assigns) do
    ~H"""
    <div
      {@rest}
      phx-mounted={!@hide && show_slide_over(@origin, @id)}
      phx-remove={hide_slide_over(@origin, @id, @close_slide_over_target)}
      class="hidden pc-slide-over"
      id={@id}
    >
      <div id={"#{@id}-overlay"} class="hidden pc-slideover__overlay" aria-hidden="true"></div>

      <div
        class={["pc-slideover__wrapper", get_margin_classes(@origin), @class]}
        role="dialog"
        aria-label="slide-over-content-wrapper"
        aria-modal="true"
      >
        <div
          id={"#{@id}-content"}
          class={get_classes(@max_width, @origin, @class)}
          phx-click-away={
            @close_on_click_away && hide_slide_over(@origin, @id, @close_slide_over_target)
          }
          phx-window-keydown={
            @close_on_escape && hide_slide_over(@origin, @id, @close_slide_over_target)
          }
          phx-key="escape"
        >
          <!-- Header -->
          <div class="pc-slideover__header">
            <div class="pc-slideover__header__container">
              <div :if={@title} class="pc-slideover__header__text">
                {@title}
              </div>

              <button
                type="button"
                phx-click={hide_slide_over(@origin, @id, @close_slide_over_target)}
                class="pc-slideover__header__button"
              >
                <div class="sr-only">Close</div>
                <svg class="pc-slideover__header__close-svg">
                  <path d="M7.95 6.536l4.242-4.243a1 1 0 111.415 1.414L9.364 7.95l4.243 4.242a1 1 0 11-1.415 1.415L7.95 9.364l-4.243 4.243a1 1 0 01-1.414-1.415L6.536 7.95 2.293 3.707a1 1 0 011.414-1.414L7.95 6.536z" />
                </svg>
              </button>
            </div>
          </div>
          <!-- Content -->
          <div class="pc-slideover__content">
            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show_slide_over(origin, id \\ "slide-over") do
    {start_class, end_class} = get_transition_classes(origin)

    %JS{}
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-overlay",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-content",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", start_class, end_class}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  # The live view that calls <.slide_over> will need to handle the "close_slide_over" event. eg:
  # def handle_event("close_slide_over", _, socket) do
  #   {:noreply, push_patch(socket, to: Routes.moderate_users_path(socket, :index))}
  # end
  def hide_slide_over(origin, id \\ "slide-over", close_slide_over_target \\ nil) do
    {end_class, start_class} = get_transition_classes(origin)

    js =
      JS.remove_class("overflow-hidden", to: "body")
      |> JS.hide(
        transition: {"ease-in duration-200", "opacity-100", "opacity-0"},
        to: "##{id}-overlay"
      )
      |> JS.hide(
        transition: {"ease-in duration-200", start_class, end_class},
        to: "##{id}-content"
      )
      |> JS.hide(to: "##{id}", transition: {"duration-200", "", ""})

    if close_slide_over_target do
      JS.push(js, "close_slide_over", target: close_slide_over_target)
    else
      JS.push(js, "close_slide_over")
    end
  end

  defp get_transition_classes(origin) do
    case origin do
      "left" -> {"-translate-x-full", "translate-x-0"}
      "right" -> {"translate-x-full", "translate-x-0"}
      "top" -> {"-translate-y-full", "translate-y-0"}
      "bottom" -> {"translate-y-full", "translate-y-0"}
    end
  end

  defp get_classes(max_width, origin, class) do
    base_classes = "hidden pc-slideover__box"

    slide_over_classes =
      case origin do
        "left" -> "fixed left-0 inset-y-0 transform -translate-x-full"
        "right" -> "fixed right-0 inset-y-0 transform translate-x-full"
        "top" -> "fixed inset-x-0 top-0 transform -translate-y-full"
        "bottom" -> "fixed inset-x-0 bottom-0 transform translate-y-full"
      end

    max_width_class =
      case origin do
        x when x in ["left", "right"] ->
          "pc-slideover__box--#{max_width}"

        x when x in ["top", "bottom"] ->
          ""
      end

    custom_classes = class

    [slide_over_classes, max_width_class, base_classes, custom_classes]
  end

  defp get_margin_classes(margin) do
    case margin do
      "left" -> "mr-10"
      "right" -> "ml-10"
      "top" -> "mb-10"
      "bottom" -> "mt-10"
    end
  end
end
