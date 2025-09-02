#!/bin/bash

# detect_file_format:
#   Enhanced format detection including RFC 5424 syslog
detect_file_format_orig() {
    local file="$1"
    local line1=$(head -1 "$file")
    local line2=$(head -2 "$file" | tail -1)
    local line3=$(head -3 "$file" | tail -1)
    
    # Check for RFC 5424 syslog format (even with missing fields)
    if echo "$line1" | grep -qE '^<[0-9]+>[0-9]' && \
       echo "$line2" | grep -qE '^<[0-9]+>[0-9]' && \
       echo "$line3" | grep -qE '^<[0-9]+>[0-9]'; then
       echo "syslog"    
     # Check for pipe-separated format with better pattern matching - FIXED
    elif echo "$line1" | grep -qE '^([^|]*\|){2,}' && \
         echo "$line2" | grep -qE '^([^|]*\|){2,}'; then
        echo "pipe"
    # Check for JSON logs
    elif echo "$line1" | grep -q "^{" && echo "$line2" | grep -q "^{" && echo "$line3" | grep -q "^{"; then
        echo "jsonlog"
    # Check for Apache/Nginx access logs
    elif echo "$line1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.*HTTP/[0-9]+\.[0-9]+" [0-9]{3} '; then
        echo "weblog"
    # Check for BSD syslog format (older format)
    elif echo "$line1" | grep -qE '^[A-Z][a-z]{2} [ 0-9][0-9] [0-9]{2}:[0-9]{2}:[0-9]{2} '; then
        echo "bsdsyslog"
    # Check for timestamped application logs
    elif echo "$line1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'; then
        echo "applog"
    # Check for colon-separated format (like /etc/passwd)
    elif echo "$line1" | grep -qE '^([^:]*:){2,}' && \
         echo "$line2" | grep -qE '^([^:]*:){2,}'; then
        echo "colon"
    # Check for tab-separated (TSV)
    elif echo "$line1" | grep -q $'\t' && echo "$line2" | grep -q $'\t'; then
        echo "tsv"
    # Check for semicolon-separated
    elif echo "$line1" | grep -q ";" && echo "$line2" | grep -q ";"; then
        echo "semicolon"
    # Check for CSV format
    elif echo "$line1" | grep -q "," && echo "$line2" | grep -q ","; then
        echo "csv"
    # Check for MULTI-space-separated (like kubectl output) - treat as fixed-width
    elif echo "$line1" | grep -q "[[:space:]]\{2,\}" && echo "$line2" | grep -q "[[:space:]]\{2,\}"; then
        echo "fixed"  # Treat multi-space as fixed-width
    # Check for SINGLE-space-separated
    elif [ $(echo "$line1" | awk '{print NF}') -gt 1 ] && [ $(echo "$line2" | awk '{print NF}') -gt 1 ]; then
        echo "singlespace"
    else
        echo "fixed"
    fi
}

#!/bin/bash

# detect_file_format:
#   Enhanced format detection including RFC 5424 syslog
detect_file_format() {
    local file="$1"
    local line1=$(head -1 "$file")
    local line2=$(head -2 "$file" | tail -1)
    local line3=$(head -3 "$file" | tail -1)
    
    # Check for RFC 5424 syslog format (even with missing fields)
    if echo "$line1" | grep -qE '^<[0-9]+>[0-9]' && \
       echo "$line2" | grep -qE '^<[0-9]+>[0-9]' && \
       echo "$line3" | grep -qE '^<[0-9]+>[0-9]'; then
       echo "syslog"    
     # Check for pipe-separated format with better pattern matching
    elif echo "$line1" | grep -qE '^([^|]*\|){2,}' && \
         echo "$line2" | grep -qE '^([^|]*\|){2,}'; then
        echo "pipe"
    # Check for JSON logs
    elif echo "$line1" | grep -q "^{" && echo "$line2" | grep -q "^{" && echo "$line3" | grep -q "^{"; then
        echo "jsonlog"
    # Check for Apache/Nginx access logs - FIXED PATTERN
    elif echo "$line1" | grep -qE '^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[[:space:]]*[-]|\[).*HTTP/[0-9]+\.[0-9]+" [0-9]{3}' && \
         echo "$line2" | grep -qE '^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[[:space:]]*[-]|\[).*HTTP/[0-9]+\.[0-9]+" [0-9]{3}'; then
        echo "weblog"
    # Check for BSD syslog format (older format)
    elif echo "$line1" | grep -qE '^[A-Z][a-z]{2} [ 0-9][0-9] [0-9]{2}:[0-9]{2}:[0-9]{2} '; then
        echo "bsdsyslog"
    # Check for timestamped application logs
    elif echo "$line1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'; then
        echo "applog"
    # Check for colon-separated format (like /etc/passwd)
    elif echo "$line1" | grep -qE '^([^:]*:){2,}' && \
         echo "$line2" | grep -qE '^([^:]*:){2,}'; then
        echo "colon"
    # Check for tab-separated (TSV)
    elif echo "$line1" | grep -q $'\t' && echo "$line2" | grep -q $'\t'; then
        echo "tsv"
    # Check for semicolon-separated
    elif echo "$line1" | grep -q ";" && echo "$line2" | grep -q ";"; then
        echo "semicolon"
    # Check for CSV format
    elif echo "$line1" | grep -q "," && echo "$line2" | grep -q ","; then
        echo "csv"
    # Check for MULTI-space-separated (like kubectl output) - treat as fixed-width
    elif echo "$line1" | grep -q "[[:space:]]\{2,\}" && echo "$line2" | grep -q "[[:space:]]\{2,\}"; then
        echo "fixed"  # Treat multi-space as fixed-width
    # Check for SINGLE-space-separated
    elif [ $(echo "$line1" | awk '{print NF}') -gt 1 ] && [ $(echo "$line2" | awk '{print NF}') -gt 1 ]; then
        echo "singlespace"
    else
        echo "fixed"
    fi
}


# fill_empty_values_colon:
#   Colon-separated file processing
fill_empty_values_colon() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_value="${global_fill:-${fill_array[0]}}"
    
    local line_number=0
    while IFS= read -r line; do
        ((line_number++))
        
        if [ "$has_header" = "true" ] && [ $line_number -eq 1 ]; then
            echo "$line"
            continue
        fi
        
        if [[ "$line" =~ ^[-+=|[:space:]]*$ ]]; then
            echo "$line"
            continue
        fi
        
        echo "$line" | sed "
        s/::/:${fill_value}:/g;
        s/^:/${fill_value}:/;
        s/:$/:${fill_value}/;
        "
    done < "$file"
}

# fill_empty_values_csv:
#   CSV file processing
fill_empty_values_csv() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    awk -F, -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN { split(fill_str, fill_arr, " ") }
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
}

# fill_empty_values_tsv:
#   TSV file processing
fill_empty_values_tsv() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    awk -F$'\t' -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN { split(fill_str, fill_arr, " ") }
    {
        if (has_header == "true" && NR == 1) { print; next }
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "") { output = output (output ? "\t" : "") fill_value }
            else { output = output (output ? "\t" : "") $i }
        }
        print output
    }' "$file"
}

# fill_empty_values_semicolon:
#   Semicolon-separated file processing
fill_empty_values_semicolon() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    awk -F';' -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN { split(fill_str, fill_arr, " ") }
    {
        if (has_header == "true" && NR == 1) { print; next }
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "") { output = output (output ? ";" : "") fill_value }
            else { output = output (output ? ";" : "") $i }
        }
        print output
    }' "$file"
}

# fill_empty_values_pipe:
#   Pipe-separated file processing
fill_empty_values_pipe() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    awk -F'|' -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN { split(fill_str, fill_arr, " ") }
    {
        if (has_header == "true" && NR == 1) { print; next }
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "") { output = output (output ? "|" : "") fill_value }
            else { output = output (output ? "|" : "") $i }
        }
        print output
    }' "$file"
}

# pretty_print_pipe:
#   Pretty print pipe-separated data with properly aligned columns
pretty_print_pipe() {
    local input_data="$1"
    local has_header="${2:-true}"
    
    # Read all lines into an array from the input data
    local -a lines
    mapfile -t lines <<< "$input_data"
    
    # Find maximum width for each column
    local -a col_widths
    local line_count=0
    
    for line in "${lines[@]}"; do
        ((line_count++))
        if [ "$has_header" = "true" ] && [ $line_count -eq 1 ]; then
            continue
        fi
        
        # Split line by pipe
        IFS='|' read -ra fields <<< "$line"
        for i in "${!fields[@]}"; do
            local field="${fields[$i]}"
            local field_length=${#field}
            
            # Initialize or update column width
            if [ -z "${col_widths[$i]:-}" ] || [ $field_length -gt ${col_widths[$i]} ]; then
                col_widths[$i]=$field_length
            fi
        done
    done
    
    # Now process each line with proper formatting
    line_count=0
    for line in "${lines[@]}"; do
        ((line_count++))
        
        # Split line by pipe
        IFS='|' read -ra fields <<< "$line"
        
        # Build formatted output
        local formatted_line=""
        for i in "${!fields[@]}"; do
            local field="${fields[$i]}"
            local width="${col_widths[$i]:-0}"
            
            # Right-align numbers, left-align everything else
            if [[ "$field" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                formatted_line+="| $(printf "%${width}s" "$field") "
            else
                formatted_line+="| $(printf "%-${width}s" "$field") "
            fi
        done
        
        # Add trailing pipe if we have columns
        if [ ${#fields[@]} -gt 0 ]; then
            formatted_line+="|"
        fi
        
        # Print header separator after header
        if [ "$has_header" = "true" ] && [ $line_count -eq 1 ]; then
            echo "$formatted_line"
            
            # Print separator line
            local separator=""
            for width in "${col_widths[@]}"; do
                separator+="+$(printf '%*s' $((width + 2)) | tr ' ' '-')"
            done
            separator+="+"
            echo "$separator"
        else
            echo "$formatted_line"
        fi
    done
}

# fill_empty_values_singlespace:
#   Single-space separated file processing
fill_empty_values_singlespace() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    awk -F' ' -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN { split(fill_str, fill_arr, " ") }
    {
        if (has_header == "true" && NR == 1) { print; next }
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "") { output = output (output ? " " : "") fill_value }
            else { output = output (output ? " " : "") $i }
        }
        print output
    }' "$file"
}

# fill_empty_values_log:
#   Log file processing as space-separated
fill_empty_values_log() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    awk -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN { split(fill_str, fill_arr, " ") }
    {
        if (has_header == "true" && NR == 1) { print; next }
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "") { output = output (output ? " " : "") fill_value }
            else { output = output (output ? " " : "") $i }
        }
        print output
    }' "$file"
}

# fill_empty_values_fixed:
#   Fixed-width file processing (working) - for kubectl-style output
fill_empty_values_fixed() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local header=$(head -1 "$file")
    
    local positions=()
    positions[1]=1
    for ((i=2; i<=num_columns; i++)); do
        positions[$i]=$(echo "$header" | awk -v col="$i" '{print index($0, $col)}')
    done
    
    local fill_string="${fill_array[*]}"
    local pos_string="${positions[*]}"
    
    awk -v cols="$num_columns" -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" -v pos_str="$pos_string" '
    BEGIN {
        split(fill_str, fill_arr, " ")
        split(pos_str, pos_arr, " ")
    }
    {
        if (has_header == "true" && NR == 1) {
            print
            next
        }
        
        for (i=1; i<=cols; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            
            start_pos = pos_arr[i]
            if (i < cols) {
                end_pos = pos_arr[i+1]
            } else {
                end_pos = length($0) + 1
            }
            field_length = end_pos - start_pos
            
            original_field = substr($0, start_pos, field_length)
            trimmed_field = original_field
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", trimmed_field)
            
            if (trimmed_field == "") {
                printf "%s", fill_value
                spaces_needed = field_length - length(fill_value)
                if (spaces_needed > 0) printf "%*s", spaces_needed, ""
            } else {
                printf "%s", original_field
            }
        }
        printf "\n"
    }' "$file"
}


# fill_empty_values_syslog:
#   Correct RFC 5424 parsing with proper field structure
fill_empty_values_syslog() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    awk -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN {
        split(fill_str, fill_arr, " ")
    }
    {
        if (has_header == "true" && NR == 1) {
            print
            next
        }
        
        line = $0
        output = ""
        field_num = 1
        
        # Extract PRI+VERSION (first field, no space between them)
        if (match(line, /^<[0-9]+>[0-9]/)) {
            pri_version = substr(line, RSTART, RLENGTH)
            line = substr(line, RSTART + RLENGTH)
            output = pri_version
            field_num++
        } else {
            # Missing PRI+VERSION, fill it
            fill_value = (global_fill != "") ? global_fill : fill_arr[1]
            output = fill_value
            field_num++
        }
        
        # Process next 5 fields (space-separated)
        for (; field_num <= 6; field_num++) {
            # Remove leading spaces
            sub(/^ /, "", line)
            
            if (line == "") break
            
            # Extract next field
            if (match(line, /^[^ ]+/)) {
                field_content = substr(line, RSTART, RLENGTH)
                line = substr(line, RSTART + RLENGTH)
                
                if (field_content == "" || field_content == " ") {
                    # Empty field, fill it
                    fill_value = (global_fill != "") ? global_fill : fill_arr[field_num]
                    output = output " " fill_value
                } else {
                    output = output " " field_content
                }
            } else {
                # Missing field, fill it
                fill_value = (global_fill != "") ? global_fill : fill_arr[field_num]
                output = output " " fill_value
            }
        }
        
        # Everything remaining is the MESSAGE - preserve all spaces
        sub(/^ /, "", line)
        if (line == "" || line == " ") {
            message = (global_fill != "") ? global_fill : "No message"
        } else {
            message = line
        }
        
        print output " " message
    }' "$file"
}


# fill_empty_values_bsdsyslog:
#   Traditional BSD syslog format processing
fill_empty_values_bsdsyslog() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    # Use simple space separation for BSD syslog
    awk -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN {
        split(fill_str, fill_arr, " ")
    }
    {
        if (has_header == "true" && NR == 1) {
            print
            next
        }
        
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "" || $i == ":") {
                output = output (output ? " " : "") fill_value
            } else {
                output = output (output ? " " : "") $i
            }
        }
        print output
    }' "$file"
}

# Main execution with proper POSIX argument parsing
filename=""
fill_array=()
global_fill=""
has_header="true"
pretty_print=false
use_stdin=false

# First, check if any help option is requested
for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        echo "Usage: $0 [OPTIONS] [filename]"
        echo "Options:"
        echo "  -h, --help           Show this help message"
        echo "  -f, --fill <values>   Fill values for empty fields (space-separated)"
        echo "  -g, --global <value>  Global fill value for all empty fields"
        echo "  -n, --no-header       Input file has no header row"
        echo "  -p, --pretty          Pretty print output (pipe format only)"
        echo
        echo "Examples:"
        echo "  $0 -f \"Unknown 0 N/A\" -n -p data.txt"
        echo "  $0 --global MISSING --no-header file.csv"
        echo "  $0 data.txt -f \"Unknown 0 N/A\" -n -p"
        echo "  cat data.txt | $0 -f \"Unknown 0 N/A\"   # Read from stdin"
        echo "  kubectl get pods | $0 -n -p             # Read from stdin"
        exit 0
    fi
done

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--fill)
            if [ $# -lt 2 ]; then
                echo "Error: Missing argument for $1" >&2
                exit 1
            fi
            shift
            fill_array=($1)
            ;;
        -g|--global)
            if [ $# -lt 2 ]; then
                echo "Error: Missing argument for $1" >&2
                exit 1
            fi
            shift
            global_fill="$1"
            ;;
        -n|--no-header)
            has_header="false"
            ;;
        -p|--pretty)
            pretty_print=true
            ;;
        --)
            shift
            # Remaining arguments are treated as filenames
            while [[ $# -gt 0 ]]; do
                if [ -z "$filename" ]; then
                    filename="$1"
                else
                    echo "Error: Multiple filenames specified" >&2
                    exit 1
                fi
                shift
            done
            break
            ;;
        -)  # Explicit stdin indicator (for compatibility)
            use_stdin=true
            ;;
        -*)  # Handle combined short options and unknown options
            # Extract all characters after the dash
            options="${1:1}"
            # Process each character individually
            for (( i=0; i<${#options}; i++ )); do
                opt_char="${options:$i:1}"
                case "$opt_char" in
                    h)
                        echo "Usage: $0 [OPTIONS] [filename]"
                        echo "Options:"
                        echo "  -h, --help           Show this help message"
                        echo "  -f, --fill <values>   Fill values for empty fields (space-separated)"
                        echo "  -g, --global <value>  Global fill value for all empty fields"
                        echo "  -n, --no-header       Input file has no header row"
                        echo "  -p, --pretty          Pretty print output (pipe format only)"
                        exit 0
                        ;;
                    f)
                        if [ $# -lt 2 ]; then
                            echo "Error: Missing argument for -f" >&2
                            exit 1
                        fi
                        # Get the next argument for -f
                        fill_array=($2)
                        # Skip the next argument since we consumed it
                        shift
                        ;;
                    g)
                        if [ $# -lt 2 ]; then
                            echo "Error: Missing argument for -g" >&2
                            exit 1
                        fi
                        # Get the next argument for -g
                        global_fill="$2"
                        # Skip the next argument since we consumed it
                        shift
                        ;;
                    n)
                        has_header="false"
                        ;;
                    p)
                        pretty_print=true
                        ;;
                    *)
                        echo "Error: Unknown option -$opt_char" >&2
                        echo "Use -h or --help for usage information" >&2
                        exit 1
                        ;;
                esac
            done
            ;;
        *)
            if [ -z "$filename" ]; then
                filename="$1"
            else
                echo "Error: Multiple filenames specified: $filename and $1" >&2
                exit 1
            fi
            ;;
    esac
    shift
done

# If no filename provided, use stdin
if [ -z "$filename" ]; then
    use_stdin=true
fi

# Handle stdin (either explicitly with - or implicitly when no filename)
if [ "$use_stdin" = true ] || [ "$filename" = "-" ]; then
    # Create a temporary file for stdin content
    TEMP_FILE=$(mktemp)
    cat > "$TEMP_FILE"
    filename="$TEMP_FILE"
fi

# Check if file exists (unless it's stdin)
if [ ! -f "$filename" ]; then
    echo "Error: File $filename not found!" >&2
    exit 1
fi

if [ ! -r "$filename" ]; then
    echo "Error: File $filename is not readable" >&2
    exit 1
fi


# Clean up temporary file if we used stdin
if [ "$use_stdin" = true ] || [ "$filename" = "-" ]; then
    rm -f "$TEMP_FILE"
fi

file_format=$(detect_file_format "$filename")
echo "Detected format: $file_format" >&2

# Process the file first, then apply pretty printing if requested
case "$file_format" in
    "csv")
        col_count=$(head -1 "$filename" | awk -F, '{print NF}')
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing as CSV with $col_count columns" >&2
        processed_data=$(fill_empty_values_csv "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        ;;
    "tsv")
        col_count=$(head -1 "$filename" | awk -F$'\t' '{print NF}')
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing as TSV with $col_count columns" >&2
        processed_data=$(fill_empty_values_tsv "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        ;;
    "semicolon")
        col_count=$(head -1 "$filename" | awk -F';' '{print NF}')
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing as semicolon-separated with $col_count columns" >&2
        processed_data=$(fill_empty_values_semicolon "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        ;;
    "pipe")
        col_count=$(head -1 "$filename" | awk -F'|' '{print NF}')
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing as pipe-separated with $col_count columns" >&2
        processed_data=$(fill_empty_values_pipe "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        
        # Apply pretty printing after filling empty values
        if [ "$pretty_print" = true ]; then
            echo "Pretty printing pipe-separated data" >&2
            pretty_print_pipe "$processed_data" "$has_header"
            exit 0
        fi
        ;;
    "singlespace")
        col_count=$(head -1 "$filename" | awk '{print NF}')
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing as single-space-separated with $col_count columns" >&2
        processed_data=$(fill_empty_values_singlespace "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        ;;
    "colon")
        col_count=$(awk -F: '/^[-+=|[:space:]]*$/ { next } { gsub(/[^:]/, ""); fields = length($0) + 1; if (fields > max) max = fields } END { print (max > 0 ? max : 1) }' "$filename")
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing as colon-separated with $col_count columns" >&2
        processed_data=$(fill_empty_values_colon "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        ;;
    "syslog")  # RFC 5424 syslog
        col_count=7
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing as RFC 5424 syslog with $col_count columns" >&2
        processed_data=$(fill_empty_values_syslog "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        ;;
    "bsdsyslog")  # Traditional BSD syslog
        col_count=6
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing as BSD syslog with $col_count columns" >&2
        processed_data=$(fill_empty_values_bsdsyslog "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        ;;
    "weblog"|"applog"|"jsonlog")
        col_count=$(head -1 "$filename" | awk '{print NF}')
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing $file_format as space-separated with $col_count columns" >&2
        processed_data=$(fill_empty_values_log "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        ;;
    *)
        col_count=$(head -1 "$filename" | awk '{print NF}')
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing as fixed-width with $col_count columns" >&2
        processed_data=$(fill_empty_values_fixed "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        ;;
esac

# Output the processed data (unless pretty print was already handled in pipe case)
echo "$processed_data"