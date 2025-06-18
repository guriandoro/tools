#!/bin/bash

# Performance test script for text generation functions
# This script compares the performance of the improved batch-based functions

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Performance Test for Text Generation Functions${NC}"
echo "=================================================="
echo ""

# Test parameters
TEST_LENGTHS=(100 1000 10000 50000)
NUM_TESTS=3

# Source the main script to get the functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/generate_long_text_inserts.sh"

if [ ! -f "$MAIN_SCRIPT" ]; then
    echo -e "${RED}Error: Main script not found at $MAIN_SCRIPT${NC}"
    exit 1
fi

# Source the functions from the main script
source "$MAIN_SCRIPT"

# Function to measure execution time
measure_time() {
    local func_name="$1"
    local length="$2"
    local start_time=$(date +%s%N)
    
    # Call the function
    local result
    if [ "$func_name" = "random" ]; then
        result=$(generate_random_text "$length")
    elif [ "$func_name" = "lorem" ]; then
        result=$(generate_lorem_text "$length")
    fi
    
    local end_time=$(date +%s%N)
    local duration=$((end_time - start_time))
    local duration_ms=$((duration / 1000000))
    
    echo "$duration_ms"
}

# Test random text generation
echo -e "${YELLOW}Testing Random Text Generation:${NC}"
echo "Length (chars) | Time (ms) | Avg (ms)"
echo "---------------|-----------|---------"

for length in "${TEST_LENGTHS[@]}"; do
    total_time=0
    
    for ((i=1; i<=NUM_TESTS; i++)); do
        time_ms=$(measure_time "random" "$length")
        total_time=$((total_time + time_ms))
    done
    
    avg_time=$((total_time / NUM_TESTS))
    printf "%-14s | %-9s | %-7s\n" "$length" "$time_ms" "$avg_time"
done

echo ""

# Test Lorem Ipsum generation
echo -e "${YELLOW}Testing Lorem Ipsum Generation:${NC}"
echo "Length (chars) | Time (ms) | Avg (ms)"
echo "---------------|-----------|---------"

for length in "${TEST_LENGTHS[@]}"; do
    total_time=0
    
    for ((i=1; i<=NUM_TESTS; i++)); do
        time_ms=$(measure_time "lorem" "$length")
        total_time=$((total_time + time_ms))
    done
    
    avg_time=$((total_time / NUM_TESTS))
    printf "%-14s | %-9s | %-7s\n" "$length" "$time_ms" "$avg_time"
done

echo ""
echo -e "${GREEN}Performance test completed!${NC}"
echo ""
echo -e "${BLUE}Key improvements:${NC}"
echo "- Batch processing reduces string concatenation overhead"
echo "- /dev/urandom provides faster random data when available"
echo "- Pre-calculated word lengths improve Lorem Ipsum generation"
echo "- Configurable batch sizes optimize memory usage" 