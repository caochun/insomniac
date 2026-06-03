# Insomniac

macOS menu bar app that monitors processes preventing your screen or system from sleeping.

## Features

- Detects processes holding `PreventUserIdleDisplaySleep`, `PreventUserIdleSystemSleep`, `PreventSystemSleep`, and `NoIdleSleepAssertion` power assertions
- Blinking warning icon when blockers are detected; quiet moon icon when idle
- Shows process name, PID, assertion type, and duration
- For `caffeinate` processes, traces and displays the parent caller
- Terminate or force-terminate blocking processes directly from the menu
- Auto-refreshes every 10 seconds
- Filters out known system daemons (powerd, WindowServer, bluetoothd, etc.)

## Build & Run

Requires Swift 5.9+ and macOS 13+.

```bash
swift build
.build/debug/Insomniac
```

Release build:

```bash
swift build -c release
.build/release/Insomniac
```

## Testing

Start a test blocker:

```bash
caffeinate -d -t 60
```

The menu bar icon should start blinking. Click it to see the process and terminate it.
