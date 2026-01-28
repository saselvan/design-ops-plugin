#!/bin/bash
# ==============================================================================
# run-ralph.sh - Entry Point for RALPH Runner
# Simpler interface to runner.sh with auto-detection
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Make executable
chmod +x "$SCRIPT_DIR/runner.sh"

# Forward all arguments to runner
exec "$SCRIPT_DIR/runner.sh" "$@"
