

Data Format Processor: Comprehensive Documentation
==================================================

📋 Overview
-----------

This script provides automated format detection and empty field filling for various file formats. It supports over 10 different formats with intelligent pattern matching and processing.

🎯 Main Functions Documentation
-------------------------------

### `detect_file_format()` - Format Detection Function

    # detect_file_format:
    #   Enhanced format detection including RFC 5424 syslog
    #   Parameters: file - Path to the file to analyze
    #   Returns: Format name as string
    detect_file_format() {
        local file="$1"
        local line1=$(head -1 "$file")
        local line2=$(head -2 "$file" | tail -1)
        local line3=$(head -3 "$file" | tail -1)

#### Pattern Matching Explanations:

**1\. RFC 5424 Syslog Detection:**

    '^<[0-9]+>[0-9]'
    # ^         - Start of line
    # <[0-9]+>  - Priority field: < followed by 1+ digits followed by >
    # [0-9]     - Version number: single digit
    # Matches: <134>1 2023-01-15T10:30:00Z host app msg

**2\. Pipe-Separated Detection:**

    '^([^|]*\|){2,}'
    # ^         - Start of line  
    # ([^|]*\|) - Group: 0+ non-pipe chars followed by pipe
    # {2,}      - 2 or more occurrences of the group
    # Matches: field1|field2|field3|field4

**3\. JSON Log Detection:**

    "^{"  # Simple check for lines starting with {
    # Matches any JSON object: {"key": "value"}

**4\. Web Log Detection (Improved):**

    '^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[[:space:]]*[-]|\[).*HTTP/[0-9]+\.[0-9]+" [0-9]{3}'
    # ^         - Start of line
    # (
    #   [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+  - IPv4 address
    #   |                                - OR
    #   [[:space:]]*[-]                  - Optional spaces + hyphen (missing IP)
    #   |                                - OR  
    #   \[                               - Opening bracket (IPv6)
    # )
    # .*HTTP/[0-9]+\.[0-9]+"            - HTTP version pattern
    # [0-9]{3}                           - 3-digit status code
    # Matches: 192.168.1.1 - - [15/Jan/2023:10:30:00 +0000] "GET / HTTP/1.1" 200

**5\. BSD Syslog Detection:**

    '^[A-Z][a-z]{2} [ 0-9][0-9] [0-9]{2}:[0-9]{2}:[0-9]{2} '
    # ^                 - Start of line
    # [A-Z][a-z]{2}     - Month abbreviation: Jan, Feb, etc.
    # [ 0-9][0-9]       - Day (1-31 with leading space)
    # [0-9]{2}:[0-9]{2}:[0-9]{2} - Time: HH:MM:SS
    # Matches: Jan 15 10:30:00 hostname message

**6\. Colon-Separated Detection:**

    '^([^:]*:){2,}'
    # ^         - Start of line
    # ([^:]*:)  - Group: 0+ non-colon chars followed by colon
    # {2,}      - 2 or more occurrences
    # Matches: field1:field2:field3:field4

**7\. Multi-Space Detection (Fixed-width):**

    "[[:space:]]\{2,\}"
    # [[:space:]] - Any whitespace character
    # \{2,\}     - 2 or more occurrences
    # Matches: column1    column2    column3 (multiple spaces)

### Processing Functions Documentation

#### `fill_empty_values_colon()` - Colon-Separated Processing

    # fill_empty_values_colon:
    #   Colon-separated file processing (like /etc/passwd)
    #   Parameters:
    #     file - Input file path
    #     num_columns - Number of columns to expect
    #     fill_array_ref - Reference to array of fill values
    #     global_fill - Global fill value (overrides array)
    #     has_header - Boolean for header presence
    fill_empty_values_colon() {
        local file="$1"
        local num_columns="$2"
        local -n fill_array_ref="$3"  # Namereference to fill array
        local global_fill="${4:-}"    # Optional global fill
        local has_header="${5:-true}" # Header flag with default

**Sed Commands Explanation:**

    s/::/:${fill_value}:/g;    # Replace double colons with fill value
    s/^:/${fill_value}:/;      # Replace leading colon
    s/:$/:${fill_value}/;      # Replace trailing colon

#### `fill_empty_values_csv()` - CSV Processing

    # fill_empty_values_csv:
    #   CSV file processing with comma separation
    #   Uses AWK for efficient column processing
    awk -F, -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN { split(fill_str, fill_arr, " ") }  # Split fill string into array
    {
        if (has_header == "true" && NR == 1) { print; next }
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "") { output = output (output ? "," : "") fill_value }
            else { output = output (output ? "," : "") $i }
        }
        print output
    }' "$file"

#### `pretty_print_pipe()` - Pretty Printing Function

    # pretty_print_pipe:
    #   Pretty print pipe-separated data with aligned columns
    #   Parameters:
    #     input_data - The data to format (string)
    #     has_header - Boolean for header presence
    pretty_print_pipe() {
        local input_data="$1"
        local has_header="${2:-true}"
        
        # Two-pass approach:
        # 1. First pass: Calculate max column widths
        # 2. Second pass: Format with proper alignment
        
        # Right-align numbers, left-align text:
        if [[ "$field" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            formatted_line+="| $(printf "%${width}s" "$field") "  # Right align
        else
            formatted_line+="| $(printf "%-${width}s" "$field") " # Left align
        fi

#### `fill_empty_values_fixed()` - Fixed-Width Processing

    # fill_empty_values_fixed:
    #   Fixed-width file processing (kubectl-style output)
    #   Calculates column positions and maintains alignment
    fill_empty_values_fixed() {
        local file="$1"
        local num_columns="$2"
        local -n fill_array_ref="$3"
        local global_fill="${4:-}"
        local has_header="${5:-true}"
        
        # Calculate column positions from header
        local positions=()
        positions[1]=1
        for ((i=2; i<=num_columns; i++)); do
            positions[$i]=$(echo "$header" | awk -v col="$i" '{print index($0, $col)}')
        done

### Main Argument Processing Logic

    # Main execution with proper POSIX argument parsing
    filename=""
    fill_array=()
    global_fill=""
    has_header="true"
    pretty_print=false
    use_stdin=false
    
    # Parse command line arguments with support for:
    # - Short options: -f, -g, -n, -p, -h
    # - Long options: --fill, --global, --no-header, --pretty, --help  
    # - Combined short options: -fnp, -ng, etc.
    # - Filename anywhere: beginning, middle, or end
    # - STDIN support: no filename or explicit -
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--fill)
                if [ $# -lt 2 ]; then
                    echo "Error: Missing argument for $1" >&2
                    exit 1
                fi
                shift
                fill_array=($1)  # Convert space-separated string to array
                ;;

### Format Processing Switch Case

    # Process the file based on detected format
    case "$file_format" in
        "csv")
            col_count=$(head -1 "$filename" | awk -F, '{print NF}')
            while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
            echo "Processing as CSV with $col_count columns" >&2
            processed_data=$(fill_empty_values_csv "$filename" "$col_count" fill_array "$global_fill" "$has_header")
            ;;

**Special Column Count Calculations:**

    # Colon-separated: Count maximum number of colons
    col_count=$(awk -F: '/^[-+=|[:space:]]*$/ { next } { gsub(/[^:]/, ""); fields = length($0) + 1; if (fields > max) max = fields } END { print (max > 0 ? max : 1) }' "$filename")
    
    # Fixed-width: Use awk field count
    col_count=$(head -1 "$filename" | awk '{print NF}')

🎯 Pattern Matching Cheat Sheet
-------------------------------

### Regex Patterns Used:

1.  **IP Address**: `[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+`
    
2.  **HTTP Pattern**: `HTTP/[0-9]+\.[0-9]+" [0-9]{3}`
    
3.  **Timestamp**: `[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}`
    
4.  **Multiple Delimiters**: `([^|]*\|){2,}` (pipe), `([^:]*:){2,}` (colon)
    
5.  **Whitespace**: `[[:space:]]\{2,\}` (2+ spaces)
    

### Special Variables:

*   `local -n fill_array_ref="$3"` - Namereference (Bash 4.3+)
    
*   `${4:-}` - Default parameter expansion (empty if not provided)
    
*   `${5:-true}` - Default parameter with default value
    
*   `$(head -1 "$file")` - Efficient first line extraction
    

🔧 Performance Considerations
-----------------------------

1.  **Efficient Detection**: Only reads first 3 lines for format detection
    
2.  **Stream Processing**: Uses AWK for most operations (memory efficient)
    
3.  **Temporary Files**: STDIN content written to temp files for file-based processing
    
4.  **Early Exit**: Help option exits immediately without processing
    

This comprehensive documentation covers all the complex pattern matching, function parameters, and processing logic used throughout the script!

---

