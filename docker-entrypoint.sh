#!/bin/bash

# Entrypoint to disable ASLR and warn the user about it.
# Instructions to re-enable are posted in the output.

# Disable ASLR
echo 0 > /proc/sys/kernel/randomize_va_space

value=$(cat /proc/sys/kernel/randomize_va_space)
if [ "$value" -ne 0 ]; then
    echo "Failed to disable ASLR. Current value: $value"
    echo "Are you sure you're runnign this container with the necessary privileges? (e.g., --privileged)"
else
    echo "ASLR has been disabled for this system. To re-enable it, run:"
    echo "echo 2 | sudo tee /proc/sys/kernel/randomize_va_space"
fi

# Switch to a non-root user for running the exercise
exec gosu user "$@"
