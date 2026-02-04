#!/usr/bin/env elixir

# Minimal SIGWINCH test - verifies OS signal handling works
# Run this, then resize your terminal - you should see messages

defmodule SigwinchTest do
  def run do
    IO.puts("Testing SIGWINCH signal handling...")
    IO.puts("PID: #{inspect(self())}")
    IO.puts("")

    # Try to register for SIGWINCH
    result = try do
      :os.set_signal(:sigwinch, :handle)
      IO.puts("✓ Successfully registered for SIGWINCH signals")
      :ok
    rescue
      e ->
        IO.puts("✗ Failed to register SIGWINCH: #{inspect(e)}")
        :error
    end

    if result == :ok do
      IO.puts("")
      IO.puts("Now resize your terminal window...")
      IO.puts("You should see 'Received SIGWINCH!' messages below")
      IO.puts("Press Ctrl+C to exit")
      IO.puts("")

      # Loop and wait for signals
      wait_for_signals(0)
    end
  end

  defp wait_for_signals(count) do
    receive do
      :sigwinch ->
        IO.puts("[#{count + 1}] Received SIGWINCH!")
        wait_for_signals(count + 1)

      other ->
        IO.puts("Received unexpected message: #{inspect(other)}")
        wait_for_signals(count)
    after
      60_000 ->
        IO.puts("\nTimeout - no signals received in 60 seconds")
        IO.puts("Total SIGWINCH signals received: #{count}")
    end
  end
end

SigwinchTest.run()
