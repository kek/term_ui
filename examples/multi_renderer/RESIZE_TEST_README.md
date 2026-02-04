# Terminal Resize Detection Test

## Overview

This is a minimal test application that verifies terminal resize detection is working correctly in TermUI. It displays the current terminal dimensions and updates them in real-time when the terminal window is resized.

## What It Tests

- **SIGWINCH Signal Handling**: Verifies the Terminal GenServer receives resize signals
- **Event.Resize Creation**: Tests that resize events are created with correct dimensions
- **Event Broadcasting**: Confirms resize events are broadcast to components
- **Screen Re-rendering**: Validates that the screen is cleared and re-rendered on resize
- **Dimension Tracking**: Ensures width and height are accurately reported

## Running the Test

### Standard Method

From the project root directory:

```bash
elixir -S mix run -r examples/multi_renderer/resize_test.ex -e "ResizeTest.run()"
```

### Alternative Methods

Using IEx (recommended for debugging):

```bash
iex -S mix
iex> Code.require_file("examples/multi_renderer/resize_test.ex")
iex> ResizeTest.run()
```

From any directory:

```bash
cd /path/to/term_ui
elixir -S mix run -r examples/multi_renderer/resize_test.ex -e "ResizeTest.run()"
```

## How to Verify

1. **Start the test** using one of the commands above
2. **Check initial display**:
   - Current terminal dimensions should be shown
   - Dimensions should match your actual terminal size
   - Resize count starts at 0

3. **Resize your terminal**:
   - Drag the corner of your terminal window to make it larger/smaller
   - Or maximize/restore the window
   - Or use your terminal's resize keyboard shortcuts

4. **Expected Results**:
   - ✅ Width and height numbers update immediately
   - ✅ Resize counter increments with each resize
   - ✅ Visual border adapts to new terminal size
   - ✅ No crashes or error messages
   - ✅ Screen clears and re-renders cleanly (no artifacts)

5. **Quit the test**: Press `q` to exit

## Success Criteria

| Check | Expected Behavior |
|-------|------------------|
| Initial dimensions | Match actual terminal size (verify with `tput cols` and `tput lines`) |
| Resize response | Dimensions update within ~100ms of resize |
| Counter increment | Increments by 1 for each resize event |
| Visual feedback | Border line length changes with width |
| Stability | No crashes, no rendering artifacts |
| Clean exit | Quits cleanly when 'q' is pressed |

## Failure Indicators

| Symptom | Likely Cause |
|---------|-------------|
| Dimensions don't update | SIGWINCH not being received or handled |
| App crashes on resize | Issue in resize event handling or rendering |
| Screen shows artifacts | Screen clear/re-render not working properly |
| Wrong dimensions | Issue in dimension detection or event creation |
| Counter doesn't increment | Resize events not being converted to messages |

## Platform Notes

- **Linux/macOS**: SIGWINCH is standard, should work out of the box
- **Windows 10+**: Requires Windows Terminal or modern terminal emulator
- **WSL**: Should work if running in Windows Terminal
- **SSH sessions**: Resize detection depends on terminal and SSH client support

## Implementation Details

The test uses TermUI's Elm architecture with minimal state:

```elixir
%{
  width: integer(),       # Current terminal width in columns
  height: integer(),      # Current terminal height in rows
  resize_count: integer() # Number of resize events received
}
```

**Key Event Handler**:
```elixir
def event_to_msg(%TermUI.Event.Resize{width: w, height: h}, _state) do
  {:msg, {:resize, w, h}}
end
```

**State Update**:
```elixir
def update({:resize, width, height}, state) do
  new_state = %{
    width: width,
    height: height,
    resize_count: state.resize_count + 1
  }
  {new_state, []}
end
```

## Debugging Tips

### Check if SIGWINCH is being sent

In a separate terminal, find the Elixir process PID and send a manual resize signal:

```bash
# Find the process
ps aux | grep "elixir.*resize_test"

# Send SIGWINCH manually (replace PID)
kill -WINCH <PID>
```

If the counter increments, SIGWINCH handling is working.

### Verify terminal capabilities

```bash
# Check current dimensions
tput cols  # width
tput lines # height

# Check if terminal supports resize detection
echo $COLUMNS $LINES
```

### Enable debug output

Modify the test to add debug logging in the `update/2` function:

```elixir
def update({:resize, width, height}, state) do
  IO.puts("DEBUG: Received resize event - #{width}x#{height}")
  # ... rest of function
end
```

## Related Files

- **Implementation**: `examples/multi_renderer/resize_test.ex`
- **Event Definition**: `lib/term_ui/event.ex` (Event.Resize struct)
- **SIGWINCH Handler**: `lib/term_ui/terminal.ex`
- **Event Dispatch**: `lib/term_ui/runtime.ex`
- **Reference Example**: `examples/multi_renderer/basic.ex`

## Next Steps

Once this basic test passes, you can:

1. Add resize detection to your own TermUI applications
2. Test more complex scenarios (rapid resizing, extreme sizes)
3. Verify behavior with different terminal emulators
4. Test resize handling in widgets (tables, viewports, etc.)
