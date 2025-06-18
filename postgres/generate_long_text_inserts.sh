#!/bin/bash

# PostgreSQL Long Text Insert Generator
# This script generates SQL INSERT statements with arbitrarily long text columns
# Useful for testing database performance and handling large text data

set -e

# Default values
DEFAULT_TABLE_NAME="test_table"
DEFAULT_NUM_ROWS=10
DEFAULT_TEXT_LENGTH=1000
DEFAULT_OUTPUT_FILE="long_text_inserts.sql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
show_usage() {
    echo -e "${BLUE}PostgreSQL Long Text Insert Generator${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --table TABLE_NAME     Table name (default: $DEFAULT_TABLE_NAME)"
    echo "  -r, --rows NUM_ROWS        Number of rows to generate (default: $DEFAULT_NUM_ROWS)"
    echo "  -l, --length TEXT_LENGTH   Length of text columns in characters (default: $DEFAULT_TEXT_LENGTH)"
    echo "  -o, --output FILE          Output file name (default: $DEFAULT_OUTPUT_FILE)"
    echo "  -c, --columns COLUMNS      Comma-separated list of column names (default: id,long_text,created_at)"
    echo "  -d, --definition FILE      Read table definition from SQL file"
    echo "  --lorem                    Use Lorem Ipsum text instead of random characters"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -t my_table -r 100 -l 5000"
    echo "  $0 --table documents --rows 50 --length 10000 --output docs.sql"
    echo "  $0 -c 'id,title,content,metadata' -l 2000"
    echo "  $0 -d table_definition.sql -t my_table -r 100"
}

# Function to parse PostgreSQL table definition from file
parse_table_definition() {
    local definition_file="$1"
    local table_name="$2"
    
    if [ ! -f "$definition_file" ]; then
        echo -e "${RED}Error: Table definition file '$definition_file' not found${NC}" >&2
        return 1
    fi
    
    echo -e "${BLUE}Reading table definition from: $definition_file${NC}" >&2
    
    # Extract column definitions from CREATE TABLE statement
    local columns=()
    local column_types=()
    local in_table=false
    local table_found=false
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*-- ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        
        # Check if this is the target table
        if [[ "$line" =~ CREATE[[:space:]]+TABLE[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\( ]]; then
            local found_table="${BASH_REMATCH[1]}"
            if [ "$found_table" = "$table_name" ]; then
                in_table=true
                table_found=true
                echo -e "${GREEN}Found table definition for: $table_name${NC}" >&2
            else
                in_table=false
            fi
            continue
        fi
        
        # If we're in the target table, parse column definitions
        if [ "$in_table" = true ]; then
            # Check for end of table definition
            if [[ "$line" =~ ^[[:space:]]*\) ]]; then
                break
            fi
            
            # Parse column definition: column_name data_type [constraints]
            if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_()]*) ]]; then
                local column_name="${BASH_REMATCH[1]}"
                local column_type="${BASH_REMATCH[2]}"
                
                # Skip constraint lines (PRIMARY KEY, FOREIGN KEY, etc.)
                if [[ "$column_name" =~ ^(PRIMARY|FOREIGN|UNIQUE|CHECK|CONSTRAINT)$ ]]; then
                    continue
                fi
                
                columns+=("$column_name")
                column_types+=("$column_type")
                echo -e "${BLUE}  Found column: $column_name ($column_type)${NC}" >&2
            fi
        fi
    done < "$definition_file"
    
    if [ "$table_found" = false ]; then
        echo -e "${RED}Error: Table '$table_name' not found in definition file${NC}" >&2
        return 1
    fi
    
    if [ ${#columns[@]} -eq 0 ]; then
        echo -e "${RED}Error: No columns found in table definition${NC}" >&2
        return 1
    fi
    
    # Store column types globally for later use
    COLUMN_TYPES=("${column_types[@]}")
    
    # Return column names as comma-separated string
    local result=""
    for ((i=0; i<${#columns[@]}; i++)); do
        if [ $i -gt 0 ]; then
            result="$result,"
        fi
        result="$result${columns[i]}"
    done
    
    echo "$result"
}

# Function to get PostgreSQL data type for column
get_postgres_type() {
    local column_name="$1"
    local column_type="$2"
    
    case "$column_type" in
        *SERIAL*|*INT*|*BIGINT*)
            echo "integer"
            ;;
        *TEXT*|*VARCHAR*|*CHAR*)
            echo "text"
            ;;
        *TIMESTAMP*|*DATE*|*TIME*)
            echo "timestamp"
            ;;
        *BOOLEAN*|*BOOL*)
            echo "boolean"
            ;;
        *NUMERIC*|*DECIMAL*|*REAL*|*DOUBLE*|*FLOAT*)
            echo "numeric"
            ;;
        *JSON*|*JSONB*)
            echo "json"
            ;;
        *)
            echo "text"  # Default to text
            ;;
    esac
}

# Function to generate appropriate value based on column type
generate_column_value() {
    local column_name="$1"
    local column_type="$2"
    local row_id="$3"
    local text_length="$4"
    local use_lorem="$5"
    
    case "$column_type" in
        integer)
            echo -n "$row_id"
            ;;
        text)
            if [ "$use_lorem" = true ]; then
                long_text=$(generate_lorem_text "$text_length")
            else
                long_text=$(generate_random_text "$text_length")
            fi
            escaped_text=$(escape_sql "$long_text")
            echo -n "'$escaped_text'"
            ;;
        timestamp)
            echo -n "'$(date -u +"%Y-%m-%d %H:%M:%S")'"
            ;;
        boolean)
            echo -n "$([ $((RANDOM % 2)) -eq 0 ] && echo 'true' || echo 'false')"
            ;;
        numeric)
            echo -n "$((RANDOM % 10000)).$((RANDOM % 100))"
            ;;
        json)
            echo -n "'{\"id\": $row_id, \"data\": \"sample\"}'"
            ;;
        *)
            # Default to text
            if [ "$use_lorem" = true ]; then
                long_text=$(generate_lorem_text "$text_length")
            else
                long_text=$(generate_random_text "$text_length")
            fi
            escaped_text=$(escape_sql "$long_text")
            echo -n "'$escaped_text'"
            ;;
    esac
}

# Function to generate random text of specified length
generate_random_text() {
    local length=$1
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?;:()[]{}'\"-+=@#$%^&*"
    local result=""
    
    for ((i=0; i<length; i++)); do
        local random_index=$((RANDOM % ${#chars}))
        result="${result}${chars:$random_index:1}"
    done
    
    echo "$result"
}

# Function to generate Lorem Ipsum text of specified length
generate_lorem_text() {
    local length=$1
    local lorem_words=("lorem" "ipsum" "dolor" "sit" "amet" "consectetur" "adipiscing" "elit" "sed" "do" "eiusmod" "tempor" "incididunt" "ut" "labore" "et" "dolore" "magna" "aliqua" "ut" "enim" "ad" "minim" "veniam" "quis" "nostrud" "exercitation" "ullamco" "laboris" "nisi" "ut" "aliquip" "ex" "ea" "commodo" "consequat" "duis" "aute" "irure" "dolor" "in" "reprehenderit" "in" "voluptate" "velit" "esse" "cillum" "dolore" "eu" "fugiat" "nulla" "pariatur" "excepteur" "sint" "occaecat" "cupidatat" "non" "proident" "sunt" "in" "culpa" "qui" "officia" "deserunt" "mollit" "anim" "id" "est" "laborum")
    
    local result=""
    local current_length=0
    
    while [ $current_length -lt $length ]; do
        local random_word=${lorem_words[$((RANDOM % ${#lorem_words[@]}))]}
        local word_with_space="$random_word "
        local word_length=${#word_with_space}
        
        if [ $((current_length + word_length)) -le $length ]; then
            result="${result}${word_with_space}"
            current_length=$((current_length + word_length))
        else
            # Fill remaining space with characters
            local remaining=$((length - current_length))
            for ((i=0; i<remaining; i++)); do
                result="${result}."
            done
            break
        fi
    done
    
    echo "$result"
}

# Function to escape single quotes in SQL
escape_sql() {
    local text="$1"
    echo "$text" | sed "s/'/''/g"
}

# Parse command line arguments
TABLE_NAME="$DEFAULT_TABLE_NAME"
NUM_ROWS="$DEFAULT_NUM_ROWS"
TEXT_LENGTH="$DEFAULT_TEXT_LENGTH"
OUTPUT_FILE="$DEFAULT_OUTPUT_FILE"
COLUMNS="id,long_text,created_at"
USE_LOREM=false
TABLE_DEFINITION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--table)
            TABLE_NAME="$2"
            shift 2
            ;;
        -r|--rows)
            NUM_ROWS="$2"
            shift 2
            ;;
        -l|--length)
            TEXT_LENGTH="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -c|--columns)
            COLUMNS="$2"
            shift 2
            ;;
        -d|--definition)
            TABLE_DEFINITION="$2"
            shift 2
            ;;
        --lorem)
            USE_LOREM=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Validate inputs
if ! [[ "$NUM_ROWS" =~ ^[0-9]+$ ]] || [ "$NUM_ROWS" -lt 1 ]; then
    echo -e "${RED}Error: Number of rows must be a positive integer${NC}"
    exit 1
fi

if ! [[ "$TEXT_LENGTH" =~ ^[0-9]+$ ]] || [ "$TEXT_LENGTH" -lt 1 ]; then
    echo -e "${RED}Error: Text length must be a positive integer${NC}"
    exit 1
fi

# If table definition file is provided, use it to get columns
if [ -n "$TABLE_DEFINITION" ]; then
    echo -e "${GREEN}Reading table definition from: $TABLE_DEFINITION${NC}"
    
    # Parse the table definition
    COLUMNS=$(parse_table_definition "$TABLE_DEFINITION" "$TABLE_NAME")
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to parse table definition${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Table definition parsed successfully${NC}"
fi

# Convert comma-separated columns to array
IFS=',' read -ra COLUMN_ARRAY <<< "$COLUMNS"

echo -e "${GREEN}Generating PostgreSQL INSERT statements...${NC}"
echo -e "${BLUE}Table:${NC} $TABLE_NAME"
echo -e "${BLUE}Rows:${NC} $NUM_ROWS"
echo -e "${BLUE}Text length:${NC} $TEXT_LENGTH characters"
echo -e "${BLUE}Columns:${NC} ${COLUMN_ARRAY[*]}"
echo -e "${BLUE}Output file:${NC} $OUTPUT_FILE"
echo -e "${BLUE}Text type:${NC} $([ "$USE_LOREM" = true ] && echo "Lorem Ipsum" || echo "Random characters")"
if [ -n "$TABLE_DEFINITION" ]; then
    echo -e "${BLUE}Table definition:${NC} $TABLE_DEFINITION"
fi
echo ""

# Create output file
> "$OUTPUT_FILE"

# Write header comment
cat >> "$OUTPUT_FILE" << EOF
-- PostgreSQL Long Text Insert Statements
-- Generated on: $(date)
-- Table: $TABLE_NAME
-- Rows: $NUM_ROWS
-- Text length: $TEXT_LENGTH characters
-- Columns: ${COLUMN_ARRAY[*]}
EOF

if [ -n "$TABLE_DEFINITION" ]; then
    echo "-- Table definition source: $TABLE_DEFINITION" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"

# Generate INSERT statements
for ((i=1; i<=NUM_ROWS; i++)); do
    echo -ne "\r${YELLOW}Generating row $i/$NUM_ROWS...${NC}"
    
    # Start INSERT statement
    echo -n "INSERT INTO $TABLE_NAME (" >> "$OUTPUT_FILE"
    
    # Add column names with proper comma separation
    for ((j=0; j<${#COLUMN_ARRAY[@]}; j++)); do
        if [ $j -gt 0 ]; then
            echo -n ", " >> "$OUTPUT_FILE"
        fi
        echo -n "${COLUMN_ARRAY[j]}" >> "$OUTPUT_FILE"
    done
    
    echo -n ") VALUES (" >> "$OUTPUT_FILE"
    
    # Generate values for each column
    for ((j=0; j<${#COLUMN_ARRAY[@]}; j++)); do
        column="${COLUMN_ARRAY[j]}"
        
        # Add comma separator (except for first column)
        if [ $j -gt 0 ]; then
            echo -n ", " >> "$OUTPUT_FILE"
        fi
        
        # Generate appropriate value based on column name and type
        if [ -n "$TABLE_DEFINITION" ]; then
            # Use column type information from table definition
            column_type="${COLUMN_TYPES[j]}"
            generate_column_value "$column" "$column_type" "$i" "$TEXT_LENGTH" "$USE_LOREM" >> "$OUTPUT_FILE"
        else
            # Use original logic based on column name patterns
            case "$column" in
                *id*)
                    echo -n "$i" >> "$OUTPUT_FILE"
                    ;;
                *created_at*|*timestamp*|*date*)
                    echo -n "'$(date -u +"%Y-%m-%d %H:%M:%S")'" >> "$OUTPUT_FILE"
                    ;;
                *text*|*content*|*description*|*data*)
                    if [ "$USE_LOREM" = true ]; then
                        long_text=$(generate_lorem_text "$TEXT_LENGTH")
                    else
                        long_text=$(generate_random_text "$TEXT_LENGTH")
                    fi
                    escaped_text=$(escape_sql "$long_text")
                    echo -n "'$escaped_text'" >> "$OUTPUT_FILE"
                    ;;
                *)
                    # Default to a simple string value
                    echo -n "'value_$i'" >> "$OUTPUT_FILE"
                    ;;
            esac
        fi
    done
    
    echo ");" >> "$OUTPUT_FILE"
done

echo ""
echo -e "${GREEN}✓ Successfully generated $NUM_ROWS INSERT statements${NC}"
echo -e "${GREEN}✓ Output saved to: $OUTPUT_FILE${NC}"

# Show file statistics
if command -v wc >/dev/null 2>&1; then
    file_size=$(wc -c < "$OUTPUT_FILE")
    line_count=$(wc -l < "$OUTPUT_FILE")
    echo -e "${BLUE}File size (bytes):${NC} $file_size"
    echo -e "${BLUE}Total lines:${NC} $line_count"
fi

echo ""
echo -e "${YELLOW}To execute these inserts in PostgreSQL:${NC}"
echo -e "  psql -d your_database -f $OUTPUT_FILE"
echo ""
echo -e "${YELLOW}To create the table first (if needed):${NC}"
echo -e "  CREATE TABLE $TABLE_NAME ("
for ((j=0; j<${#COLUMN_ARRAY[@]}; j++)); do
    column="${COLUMN_ARRAY[j]}"
    comma=""
    [ $j -lt $((${#COLUMN_ARRAY[@]}-1)) ] && comma=","
    
    case "$column" in
        *id*)
            echo -e "    $column SERIAL PRIMARY KEY$comma"
            ;;
        *created_at*|*timestamp*|*date*)
            echo -e "    $column TIMESTAMP DEFAULT CURRENT_TIMESTAMP$comma"
            ;;
        *text*|*content*|*description*|*data*)
            echo -e "    $column TEXT$comma"
            ;;
        *)
            echo -e "    $column VARCHAR(255)$comma"
            ;;
    esac
done
echo -e "  );" 