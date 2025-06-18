# PostgreSQL Tools

This directory contains tools for working with PostgreSQL databases.

## Scripts

### `generate_long_text_inserts.sh`

A bash script that generates SQL INSERT statements with arbitrarily long text columns. This is useful for:

- Testing database performance with large text data
- Stress testing text column handling
- Creating sample data for development and testing
- Benchmarking database operations with varying text sizes

#### Features

- Generate INSERT statements with configurable text column lengths
- Support for multiple column types (ID, text, timestamp, etc.)
- Option to use Lorem Ipsum text or random characters
- **NEW:** Read table definition from a SQL file and auto-detect columns/types
- SQL injection safe with proper escaping
- Progress indicators and file statistics
- Comprehensive help and usage examples

#### Usage

```bash
# Basic usage with defaults
./generate_long_text_inserts.sh

# Generate 100 rows with 5000 character text columns
./generate_long_text_inserts.sh -t documents -r 100 -l 5000

# Use Lorem Ipsum text instead of random characters
./generate_long_text_inserts.sh --lorem -l 2000

# Custom columns and output file
./generate_long_text_inserts.sh -c 'id,title,content,metadata' -o my_inserts.sql

# Read columns/types from a table definition SQL file
./generate_long_text_inserts.sh -d sample_table_definition.sql -t documents -r 10

# Show help
./generate_long_text_inserts.sh -h
```

#### Options

- `-t, --table TABLE_NAME`: Table name (default: test_table)
- `-r, --rows NUM_ROWS`: Number of rows to generate (default: 10)
- `-l, --length TEXT_LENGTH`: Length of text columns in characters (default: 1000)
- `-o, --output FILE`: Output file name (default: long_text_inserts.sql)
- `-c, --columns COLUMNS`: Comma-separated list of column names (default: id,long_text,created_at)
- `-d, --definition FILE`: **Read table definition from SQL file and auto-detect columns/types**
- `--lorem`: Use Lorem Ipsum text instead of random characters
- `-h, --help`: Show help message

#### Examples

```bash
# Generate test data for a blog system
./generate_long_text_inserts.sh \
  -t blog_posts \
  -c 'id,title,content,author,created_at' \
  -r 50 \
  -l 3000 \
  --lorem \
  -o blog_posts.sql

# Generate large dataset for performance testing
./generate_long_text_inserts.sh \
  -t performance_test \
  -r 1000 \
  -l 10000 \
  -o performance_test.sql

# Quick test with minimal data
./generate_long_text_inserts.sh -r 5 -l 100

# Use a table definition file (auto-detect columns/types)
./generate_long_text_inserts.sh -d sample_table_definition.sql -t documents -r 3 -l 100

# Use Lorem Ipsum with a table definition file
./generate_long_text_inserts.sh -d sample_table_definition.sql -t users -r 2 -l 30 --lorem
```

#### Output

The script generates a SQL file with:
- Header comments with generation metadata
- Properly escaped INSERT statements
- Progress indicators during generation
- File statistics (size, line count)
- Helpful PostgreSQL execution commands

#### Column Type Detection

The script automatically detects column types in two ways:

- **By column name pattern** (when using `-c/--columns`):
  - `*id*`: Integer values (1, 2, 3, ...)
  - `*created_at*`, `*timestamp*`, `*date*`: Current timestamp
  - `*text*`, `*content*`, `*description*`, `*data*`: Long text (configurable length)
  - Other columns: Simple string values

- **By table definition file** (when using `-d/--definition`):
  - The script parses the `CREATE TABLE` statement for the specified table
  - It extracts column names and types, and generates type-appropriate values:
    - `SERIAL`, `INT`, `BIGINT`: Integer values
    - `TEXT`, `VARCHAR`, `CHAR`: Long text (configurable length)
    - `TIMESTAMP`, `DATE`, `TIME`: Current timestamp
    - `BOOLEAN`: true/false
    - `NUMERIC`, `DECIMAL`, `REAL`, `DOUBLE`, `FLOAT`: Random numeric values
    - `JSON`, `JSONB`: Simple JSON objects
    - Other types: Treated as text

#### Safety Features

- Input validation for numeric parameters
- SQL injection prevention with proper escaping
- Error handling for invalid options
- Safe file operations

#### Requirements

- Bash shell
- Standard Unix tools (sed, wc, date)
- Optional: `numfmt` for human-readable file sizes 