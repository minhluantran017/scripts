#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker first."
    exit 1
fi

# Header
printf "%-30s %-10s %-10s %-15s %-15s\n" "CONTAINER" "CPU (%)" "MEM (%)" "MEM USAGE" "LIMIT"

# Initialize totals
total_cpu=0
total_mem=0
total_mem_used_bytes=0

# Convert sizes like MiB/GiB to bytes
to_bytes() {
    local size=$1
    local num=$(echo "$size" | grep -oE '^[0-9\.]+')
    local unit=$(echo "$size" | grep -oEi '[a-zA-Z]+')

    case $unit in
        B)   echo "$num" ;;
        KiB) echo "$(awk "BEGIN {printf \"%.0f\", $num * 1024}")" ;;
        MiB) echo "$(awk "BEGIN {printf \"%.0f\", $num * 1024 * 1024}")" ;;
        GiB) echo "$(awk "BEGIN {printf \"%.0f\", $num * 1024 * 1024 * 1024}")" ;;
        *)   echo "0" ;;
    esac
}

# Convert bytes to readable MiB format
from_bytes_mib() {
    echo "$(awk "BEGIN {printf \"%.2f MiB\", $1 / 1024 / 1024}")"
}

# Read stats line-by-line (in current shell)
while IFS='|' read -r name cpu mem usage; do
    mem_used=$(echo "$usage" | cut -d'/' -f1 | xargs)
    mem_limit=$(echo "$usage" | cut -d'/' -f2 | xargs)

    # Print container stats
    printf "%-30s %-10s %-10s %-15s %-15s\n" "$name" "$cpu" "$mem" "$mem_used" "$mem_limit"

    # Clean % signs
    cpu_val=$(echo "$cpu" | tr -d '%')
    mem_val=$(echo "$mem" | tr -d '%')

    # Add to totals
    total_cpu=$(awk "BEGIN {print $total_cpu + $cpu_val}")
    total_mem=$(awk "BEGIN {print $total_mem + $mem_val}")

    used_bytes=$(to_bytes "$mem_used")
    total_mem_used_bytes=$((total_mem_used_bytes + used_bytes))
done < <(docker stats --no-stream --format "{{.Name}}|{{.CPUPerc}}|{{.MemPerc}}|{{.MemUsage}}")

# Format total memory
total_used_fmt=$(from_bytes_mib $total_mem_used_bytes)

# Print total row (no LIMIT total)
printf "%-30s %-10.2f %-10.2f %-15s %-15s\n" "TOTAL" "$total_cpu" "$total_mem" "$total_used_fmt" "-"
