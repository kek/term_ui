# Terminal Resize Detection Test
#
# This minimal test verifies that terminal resize detection is working correctly.
# It displays current terminal dimensions and updates them in real-time when
# the terminal window is resized.
#
# Usage:
#   elixir -r examples/multi_renderer/resize_test.ex -e "ResizeTest.run()"
#
# What it tests:
#   - SIGWINCH signal handling
#   - Event.Resize event creation and broadcasting
#   - Screen re-rendering on resize
#   - Dimension tracking accuracy
#
# How to verify:
#   1. Run the test
#   2. Resize your terminal window (drag corner or maximize/restore)
#   3. Watch the dimensions update in real-time
#   4. The resize counter should increment with each resize
#   5. Press 'q' to quit

defmodule ResizeTest do
  @moduledoc """
  Minimal test for terminal resize detection.

  Displays current terminal dimensions and updates them when the terminal
  is resized. Uses TermUI's Elm architecture with minimal state tracking.
  """

  use TermUI.Elm

  # State structure
  # %{
  #   width: integer(),      # Current terminal width in columns
  #   height: integer(),     # Current terminal height in rows
  #   resize_count: integer() # Number of resize events received
  # }

  def init(_opts) do
    # Initial state - dimensions will be updated on first render
    %{
      width: 0,
      height: 0,
      resize_count: 0
    }
  end

  # Event handling - convert terminal events to messages

  def event_to_msg(%TermUI.Event.Resize{width: w, height: h}, _state) do
    {:msg, {:resize, w, h}}
  end

  def event_to_msg(%TermUI.Event.Key{key: ?q}, _state) do
    {:msg, :quit}
  end

  def event_to_msg(_event, _state), do: :ignore

  # State updates

  def update({:resize, width, height}, state) do
    require Logger
    Logger.info("ResizeTest: Received resize event - #{width}x#{height}")

    new_state = %{
      width: width,
      height: height,
      resize_count: state.resize_count + 1
    }
    {new_state, []}
  end

  def update(:quit, state) do
    {state, [:quit]}
  end

  # View rendering

  def view(state) do
    # Get dimension status text
    dim_status = if state.width > 0 and state.height > 0 do
      "#{state.width} x #{state.height}"
    else
      "Waiting for initial resize event..."
    end

    stack(:vertical, [
      # Title
      text("┌─ Terminal Resize Detection Test ─┐",
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:green)
        |> TermUI.Renderer.Style.bold()
      ),
      text(""),

      # Current dimensions
      text("Current Dimensions: #{dim_status}",
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:cyan)
        |> TermUI.Renderer.Style.bold()
      ),
      text("  Width:  #{String.pad_leading(Integer.to_string(state.width), 3)} columns",
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:yellow)
      ),
      text("  Height: #{String.pad_leading(Integer.to_string(state.height), 3)} rows",
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:yellow)
      ),
      text(""),

      # Resize counter
      text("Resize Events Received: #{state.resize_count}",
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:magenta)
      ),
      text(""),

      # Separator
      text(String.duplicate("─", 50),
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:bright_black)
      ),
      text(""),

      # Instructions
      text("Instructions:",
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:cyan)
      ),
      text("  1. Resize your terminal window (drag corner or maximize)"),
      text("  2. Watch the dimensions update in real-time"),
      text("  3. The resize counter should increment"),
      text("  4. Press 'q' to quit"),
      text(""),

      # Visual border indicator
      render_border(state.width),
      text(""),

      # Footer
      text("└─ Press 'q' to quit ─┘",
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:bright_black)
      )
    ])
  end

  # Render a border that adapts to terminal width
  defp render_border(width) when width > 0 do
    border_width = max(1, width - 6)  # Account for margins
    top = "┌" <> String.duplicate("─", border_width) <> "┐"
    middle = "│" <> String.duplicate(" ", border_width) <> "│"
    bottom = "└" <> String.duplicate("─", border_width) <> "┘"

    stack(:vertical, [
      text("Visual Border (width = #{width}):",
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:cyan)
      ),
      text(top,
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:blue)
      ),
      text(middle,
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:blue)
      ),
      text(bottom,
        TermUI.Renderer.Style.new()
        |> TermUI.Renderer.Style.fg(:blue)
      )
    ])
  end

  defp render_border(_width) do
    text("(Border will appear once dimensions are detected)",
      TermUI.Renderer.Style.new()
      |> TermUI.Renderer.Style.fg(:bright_black)
    )
  end

  # Run the application
  def run(opts \\ []) do
    all_opts = Keyword.put_new(opts, :name, :resize_test)
    TermUI.App.run(__MODULE__, all_opts)
  end
end
