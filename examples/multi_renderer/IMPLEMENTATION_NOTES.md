# Resize Test Implementation Notes

## Summary

Implemented a minimal terminal resize detection test (`resize_test.ex`) that verifies TermUI's SIGWINCH handling and resize event system works correctly. During implementation, discovered and fixed a critical bug in the Runtime module.

## Files Created

1. **`examples/multi_renderer/resize_test.ex`** (178 lines)
   - Minimal Elm architecture application
   - Displays current terminal dimensions
   - Counts and displays resize events
   - Visual border adapts to terminal width
   - Simple quit command ('q')

2. **`examples/multi_renderer/RESIZE_TEST_README.md`** (comprehensive docs)
   - Running instructions
   - Verification steps
   - Success/failure criteria
   - Platform notes
   - Debugging tips

3. **`examples/multi_renderer/IMPLEMENTATION_NOTES.md`** (this file)

## Critical Bug Fixed

### Issue

When running the resize test (or any TermUI application), the following error occurred:

```
** (EXIT from #PID<0.95.0>) exited in: GenServer.call(TermUI.Terminal, :enable_raw_mode, 5000)
    ** (EXIT) no process: the process is not alive or there's no process currently associated with the given name
```

### Root Cause

The `Runtime` module's `setup_terminal_and_buffers/0` function (line 450-473) called `Terminal.enable_raw_mode()` without first ensuring the Terminal GenServer was started.

**File**: `lib/term_ui/runtime.ex`

**Original Code** (line 450-452):
```elixir
defp setup_terminal_and_buffers do
  # Enable raw mode first
  with {:ok, _} <- Terminal.enable_raw_mode(),
```

The Terminal GenServer must be running before any Terminal module functions can be called, as they use `GenServer.call/2` to communicate with the named process.

### Solution

Added two changes to `lib/term_ui/runtime.ex`:

1. **Added helper function** (after line 481):
```elixir
defp ensure_terminal_started do
  case Process.whereis(Terminal) do
    nil ->
      Terminal.start_link()

    pid ->
      {:ok, pid}
  end
end
```

2. **Modified `setup_terminal_and_buffers/0`** (line 450-453):
```elixir
defp setup_terminal_and_buffers do
  # Ensure Terminal GenServer is started before enabling raw mode
  with {:ok, _} <- ensure_terminal_started(),
       {:ok, _} <- Terminal.enable_raw_mode(),
```

This ensures the Terminal GenServer is running before any terminal operations are attempted.

### Impact

This bug would have affected:
- All TermUI applications using raw mode
- Any application using `TermUI.App.run/2` or `TermUI.App.start/2`
- New users trying the framework for the first time

The fix is backwards compatible and doesn't change the API. Applications that were working before (perhaps due to Terminal being started elsewhere) continue to work, and applications that were failing now work correctly.

## Testing Performed

### Compilation Test
```bash
elixir -S mix compile
# ✅ No errors in runtime.ex
```

### Module Load Test
```bash
elixir -S mix run -r examples/multi_renderer/resize_test.ex -e "IO.puts(\"ResizeTest loaded\")"
# ✅ Module loads successfully
```

### Application Start Test
```bash
timeout 3 elixir -S mix run -r examples/multi_renderer/resize_test.ex -e "ResizeTest.run()"
# ✅ Application starts without GenServer errors
# ✅ Timeout indicates app is running and waiting for input
```

## How to Test Resize Detection

### Manual Test

1. Start the test:
```bash
cd /home/ke/src/term_ui
elixir -S mix run -r examples/multi_renderer/resize_test.ex -e "ResizeTest.run()"
```

2. Verify initial dimensions match terminal size

3. Resize terminal window:
   - Drag corner to make larger/smaller
   - Maximize/restore window
   - Use terminal resize shortcuts

4. Expected behavior:
   - Dimensions update immediately
   - Resize counter increments
   - Visual border adapts
   - No crashes or artifacts

5. Press 'q' to quit cleanly

### Expected Output

```
Terminal Resize Detection Test

Current Dimensions:
  Width:  120 columns
  Height:  40 rows

Resize Events: 0

────────────────────────────────────────────────

Instructions:
  1. Resize your terminal window (drag corner or maximize)
  2. Watch the dimensions update in real-time
  3. The resize counter should increment
  4. Press 'q' to quit

Visual Border:
┌──────────────────────────────────────────────┐
│                                              │
└──────────────────────────────────────────────┘

Status: Waiting for resize events...
```

(Dimensions and border width will vary based on actual terminal size)

## Architecture Notes

### State Structure

```elixir
%{
  width: integer(),       # Current terminal width in columns
  height: integer(),      # Current terminal height in rows
  resize_count: integer() # Number of resize events received
}
```

### Event Flow

1. **Signal**: OS sends SIGWINCH to Terminal GenServer when window resizes
2. **Detection**: Terminal GenServer receives signal via OTP 28 raw mode
3. **Query**: Terminal queries new dimensions via `ioctl` or equivalent
4. **Event**: `Event.Resize{width, height}` created
5. **Broadcast**: Runtime dispatches resize event to all components
6. **Conversion**: `event_to_msg/2` converts Event.Resize to `{:resize, w, h}` message
7. **Update**: `update/2` handles message and updates state
8. **Re-render**: View function called with new state
9. **Display**: New dimensions shown to user

### Key Files in Resize Flow

- `lib/term_ui/terminal.ex` - SIGWINCH signal handler
- `lib/term_ui/event.ex` - Event.Resize struct definition
- `lib/term_ui/runtime.ex` - Event dispatch and re-rendering
- `examples/multi_renderer/resize_test.ex` - Test application

## Future Improvements

### Potential Enhancements

1. **Visual Feedback**
   - Animate dimension changes
   - Show dimension diff (+5 cols, -2 rows)
   - Color-code recent changes

2. **Statistics**
   - Track min/max dimensions seen
   - Calculate average size
   - Show resize frequency

3. **Validation**
   - Compare against `tput cols`/`tput lines`
   - Detect dimension mismatches
   - Warn if dimensions seem incorrect

4. **Stress Testing**
   - Rapid resize detection
   - Handle extreme sizes (very small/large)
   - Test with different terminal emulators

### Known Limitations

1. **Platform Dependency**
   - SIGWINCH not available on all platforms
   - Windows requires Windows Terminal or modern emulator
   - SSH sessions depend on client/server support

2. **Timing**
   - Small delay between resize and detection
   - Multiple rapid resizes may be batched
   - Terminal emulator buffering may introduce lag

3. **Accuracy**
   - Dimensions are character-based (not pixels)
   - Font size changes don't trigger resize
   - Split panes may complicate detection

## Related Issues

This implementation addresses the need for:
- Testing resize detection infrastructure
- Debugging resize event flow
- Verifying SIGWINCH handling
- Demonstrating real-time dimension updates

## References

- **Plan Document**: See plan mode transcript for detailed design decisions
- **TermUI Architecture**: `notes/research/state_of_tui.md`
- **Elm Architecture**: TermUI follows The Elm Architecture pattern
- **SIGWINCH**: POSIX signal for terminal window size changes
