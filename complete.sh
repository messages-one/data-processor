#!/bin/bash








# define colors and end color is the same
red_color="\e[31m"    # begin color to highlight the ignored files
end_color="\e[0m"     # end color to end the highlight
green_color="\e[32m"  # the green color
blue_color="\e[34m"   # blue color
yellow_color="\e[33m" #yellow color
begin_color="\e[33m" #yellow color

black_color="\e[0;30m"
dark_gray_color="\e[1;30m"
light_blue_color="\e[1;34m"
light_green_color="\e[1;32m"
cyan_color_color="\e[0;36m"
light_cyan_color="\e[1;36m"
light_red_color="\e[1;31m"
purple_color="\e[0;35m"
light_purple_color="\e[1;35m"
brown_color="\e[0;33m"
light_gray_color="\e[0;37m"
white_color="\e[1;37m"

# Color control - default to NO color for data processing
use_color=false

##
# Detects the format of a given file by analyzing its first three lines.
# Supports multiple formats including syslog, pipe-separated, JSON logs, web logs,
# BSD syslog, application logs, colon-separated, TSV, semicolon-separated, CSV,
# multi-space-separated, and single-space-separated formats.
# Enhanced version of file format detection with improved web log pattern matching.
# Analyzes the first three lines of a file to determine its format.
#
# @param file The path to the file to analyze
# @return Outputs the detected file format as a string
#
##
detect_file_format() {
    local file="$1"                           # Store the input file path
    local line1=$(head -1 "$file")            # Read the first line of the file
    local line2=$(head -2 "$file" | tail -1)  # Read the second line of the file
    local line3=$(head -3 "$file" | tail -1)  # Read the third line of the file
    
    # Check for RFC 5424 syslog format (even with missing fields)
    if echo "$line1" | grep -qE '^<[0-9]+>[0-9]' && \    # Check if first line matches RFC 5424 syslog pattern
       echo "$line2" | grep -qE '^<[0-9]+>[0-9]' && \    # Check if second line matches RFC 5424 syslog pattern
       echo "$line3" | grep -qE '^<[0-9]+>[0-9]'; then   # Check if third line matches RFC 5424 syslog pattern
       echo "syslog"                                     # Output 'syslog' if all lines match
    # Check for pipe-separated format with better pattern matching
    elif echo "$line1" | grep -qE '^([^|]*\|){2,}' && \  # Check if first line has multiple pipe-separated fields
         echo "$line2" | grep -qE '^([^|]*\|){2,}'; then  # Check if second line has multiple pipe-separated fields
        echo "pipe"                                      # Output 'pipe' if both lines match
    # Check for JSON logs
    elif echo "$line1" | grep -q "^{" && \               # Check if first line starts with JSON object
         echo "$line2" | grep -q "^{" && \               # Check if second line starts with JSON object
         echo "$line3" | grep -q "^{"; then              # Check if third line starts with JSON object
        echo "jsonlog"                                   # Output 'jsonlog' if all lines match
    # Check for Apache/Nginx access logs - FIXED PATTERN
    elif echo "$line1" | grep -qE '^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[[:space:]]*[-]|\[).*HTTP/[0-9]+\.[0-9]+" [0-9]{3}' && \  # Check if first line matches enhanced web log pattern
         echo "$line2" | grep -qE '^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|[[:space:]]*[-]|\[).*HTTP/[0-9]+\.[0-9]+" [0-9]{3}'; then   # Check if second line matches enhanced web log pattern
        echo "weblog"                                    # Output 'weblog' if both lines match
    # Check for BSD syslog format (older format)
    elif echo "$line1" | grep -qE '^[A-Z][a-z]{2} [ 0-9][0-9] [0-9]{2}:[0-9]{2}:[0-9]{2} '; then  # Check if first line matches BSD syslog pattern
        echo "bsdsyslog"                                 # Output 'bsdsyslog' if match found
    # Check for timestamped application logs
    elif echo "$line1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'; then  # Check if first line matches timestamped app log pattern
        echo "applog"                                    # Output 'applog' if match found
    # Check for colon-separated format (like /etc/passwd)
    elif echo "$line1" | grep -qE '^([^:]*:){2,}' && \   # Check if first line has multiple colon-separated fields
         echo "$line2" | grep -qE '^([^:]*:){2,}'; then   # Check if second line has multiple colon-separated fields
        echo "colon"                                     # Output 'colon' if both lines match
    # Check for tab-separated (TSV)
    elif echo "$line1" | grep -q $'\t' && \              # Check if first line contains tab characters
         echo "$line2" | grep -q $'\t'; then             # Check if second line contains tab characters
        echo "tsv"                                       # Output 'tsv' if both lines match
    # Check for semicolon-separated
    elif echo "$line1" | grep -q ";" && \                # Check if first line contains semicolons
         echo "$line2" | grep -q ";"; then               # Check if second line contains semicolons
        echo "semicolon"                                 # Output 'semicolon' if both lines match
    # Check for CSV format
    elif echo "$line1" | grep -q "," && \                # Check if first line contains commas
         echo "$line2" | grep -q ","; then               # Check if second line contains commas
        echo "csv"                                       # Output 'csv' if both lines match
    # Check for MULTI-space-separated (like kubectl output) - treat as fixed-width
    elif echo "$line1" | grep -q "[[:space:]]\{2,\}" && \  # Check if first line has multiple spaces
         echo "$line2" | grep -q "[[:space:]]\{2,\}"; then  # Check if second line has multiple spaces
        echo "fixed"                                      # Output 'fixed' for multi-space separated format
    # Check for SINGLE-space-separated
    elif [ $(echo "$line1" | awk '{print NF}') -gt 1 ] && \  # Check if first line has multiple fields (single-space)
         [ $(echo "$line2" | awk '{print NF}') -gt 1 ]; then  # Check if second line has multiple fields (single-space)
        echo "singlespace"                                # Output 'singlespace' if both lines match
    else
        echo "fixed"                                      # Default to 'fixed' if no other format matches
    fi
}

##
# Processes colon-separated files, filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating if the file has a header row (default: true)
# @return Outputs the processed file with empty fields filled
##
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
            echo -e "${light_red_color}$line${end_color}"
            continue
        fi
        
        if [[ "$line" =~ ^[-+=|[:space:]]*$ ]]; then
            echo -e "${dark_gray_color}$line${end_color}"
            continue
        fi
        
        local processed_line=$(echo "$line" | sed "
        s/::/:${fill_value}:/g;
        s/^:/${fill_value}:/;
        s/:$/:${fill_value}/;
        ")
        
        echo "$processed_line"
    done < "$file"
}


##
# Processes CSV files, filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating if the file has a header row (default: true)
# @return Outputs the processed CSV file with empty fields filled
##
fill_empty_values_csv() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    # Process data first
    local processed_data=$(awk -F, -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN { split(fill_str, fill_arr, " ") }
    {
        if (has_header == "true" && NR == 1) { 
            print $0
            next 
        }
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "") { 
                output = output (output ? "," : "") fill_value
            } else { 
                output = output (output ? "," : "") $i
            }
        }
        print output
    }' "$file")
    
    # Apply colors
    if [ "$has_header" = "true" ]; then
        local header_line=$(echo "$processed_data" | head -1)
        local data_lines=$(echo "$processed_data" | tail -n +2)
        
        echo -e "${green_color}${header_line}${end_color}"
        echo "$data_lines"
    else
        echo "$processed_data"
    fi
}

##
# Processes TSV files, filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating极狐 if the file has a header row (default: true)
# @return Outputs the processed TSV file with empty fields filled
##
fill_empty_values_tsv() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    # Process data first
    local processed_data=$(awk -F$'\t' -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN { split(fill_str, fill_arr, " ") }
    {
        if (has_header == "true" && NR == 1) { 
            print $0
            next 
        }
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "") { 
                output = output (output ? "\t" : "") fill_value
            } else { 
                output = output (output ? "\t" : "") $i
            }
        }
        print output
    }' "$file")
    
    # Apply colors
    if [ "$has_header" = "true" ]; then
        local header_line=$(echo "$processed_data" | head -1)
        local data_lines=$(echo "$processed_data" | tail -n +2)
        
        echo -e "${light_blue_color}${header_line}${end_color}"
        echo "$data_lines"
    else
        echo "$processed_data"
    fi
}

##
# Processes semicolon-separated files, filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating if the file has a header row (default: true)
# @return Outputs the processed semicolon-separated file with empty fields filled
##
fill_empty_values_semicolon() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    # Process data first
    local processed_data=$(awk -F';' -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '
    BEGIN { split(fill_str, fill_arr, " ") }
    {
        if (has_header == "true" && NR == 1) { 
            print $0
            next 
        }
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "") { 
                output = output (output ? ";" : "") fill_value
            } else { 
                output = output (output ? ";" : "") $i
            }
        }
        print output
    }' "$file")
    
    # Apply colors
    if [ "$has_header" = "true" ]; then
        local header_line=$(echo "$processed_data" | head -1)
        local data_lines=$(echo "$processed_data" | tail -n +2)
        
        echo -e "${purple_color}${header_line}${end_color}"
        echo "$data_lines"
    else
        echo "$processed_data"
    fi
}

##
# Processes pipe-separated files, filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating if the file has a header row (default: true)
# @return Outputs the processed pipe-separated file with empty fields filled
##
fill_empty_values_pipe_for_color() {
    local file="$1"                           # Store the input file path
    local num_columns="$2"                    # Store the number of columns
    local -n fill_array_ref="$3"              # Reference to the array of fill values
    local global_fill="${4:-}"                # Optional global fill value (default empty)
    local has_header="${5:-true}"             # Boolean indicating if file has a header (default true)
    
    local fill_array=("${fill_array_ref[@]}") # Copy the fill array from reference
    local fill_string="${fill_array[*]}"      # Convert fill array to space-separated string
    
    awk -F'|' -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '  # Run awk with pipe as field separator
    BEGIN { split(fill_str, fill_arr, " ") } # Split fill string into array
    {
        if (has_header == "true" && NR == 1) { print; next }  # If header exists, print first line and skip
        output = ""                          # Initialize output string
        for (i=1; i<=NF; i++) {              # Loop through each field
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]  # Use global fill or array value
            if ($i == "") { output = output (output ? "|" : "") fill_value }  # Fill empty field
            else { output = output (output ? "|" : "") $i }  # Keep non-empty field
        }
        print output                         # Print processed line
    }' "$file"                               # Read input from file
}


##
# Processes pipe-separated files, filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating if the file has a header row (default: true)
# @return Outputs the processed pipe-separated file with empty fields filled
##
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
        if (has_header == "true" && NR == 1) { 
            print $0
            next 
        }
        output = ""
        for (i=1; i<=NF; i++) {
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]
            if ($i == "" || $i == " ") { 
                output = output (output ? "|" : "") fill_value
            } else { 
                output = output (output ? "|" : "") $i
            }
        }
        print output
    }' "$file"
}


##
# Pretty prints pipe-separated data with aligned columns.
#
# @param input_data The pipe-separated data to format
# @param has_header Boolean indicating if the data has a header row (default: true)
# @return Outputs the formatted data with aligned columns
##
pretty_print_pipe() {
    local input_data="$1"                     # Store the input data
    local has_header="${2:-true}"             # Boolean indicating if data has a header (default true)
    
    # Read all lines into an array from the input data
    local -a lines
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$input_data"
    
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
            
            if [[ "$field" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                formatted_line+="| $(printf "%${width}s" "$field") "
            else
                formatted_line+="| $(printf "%-${width}s" "$field") "
            fi
        done
        
        if [ ${#fields[@]} -gt 0 ]; then
            formatted_line+="|"
        fi
        
        if [ "$has_header" = "true" ] && [ $line_count -eq 1 ]; then
            echo -e "${yellow_color}${formatted_line}${end_color}"
            local separator=""
            for width in "${col_widths[@]}"; do
                separator+="+$(printf '%*s' $((width + 2)) | tr ' ' '-')"
            done
            separator+="+"
            echo -e "${dark_gray_color}${separator}${end_color}"
        else
            echo "$formatted_line"
        fi
    done
}

##
# Processes single-space-separated files, filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating if the file has a header row (default: true)
# @return Outputs the processed single-space-separated file with empty fields filled
##
fill_empty_values_singlespace() {
    local file="$1"
    local num_columns="$2"
    local -n fill_array_ref="$3"
    local global_fill="${4:-}"
    local has_header="${5:-true}"
    
    local fill_array=("${fill_array_ref[@]}")
    local fill_string="${fill_array[*]}"
    
    # Simple and reliable approach
    local processed_data=$(awk -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" -v cols="$num_columns" '
    BEGIN { 
        split(fill_str, fill_arr, " ")
    }
    {
        if (has_header == "true" && NR == 1) { 
            print $0
            next 
        }
        
        # Count consecutive spaces to determine empty fields
        line = $0
        gsub(/  +/, " @ ", line)  # Replace 2+ spaces with " @ " to mark empty field positions
        gsub(/^ /, "@ ", line)    # Replace leading space with "@ "
        gsub(/ $/, " @", line)    # Replace trailing space with " @"
        
        # Split and process
        n = split(line, fields, " ")
        output = ""
        
        for (i=1; i<=n; i++) {
            if (fields[i] == "@") {
                fill_value = (global_fill != "") ? global_fill : (i <= length(fill_arr) ? fill_arr[i] : "xxx")
                output = output (output ? " " : "") fill_value
            } else {
                output = output (output ? " " : "") fields[i]
            }
        }
        
        # Ensure we have the right number of columns
        current_fields = split(output, temp, " ")
        if (current_fields < cols) {
            for (i=current_fields+1; i<=cols; i++) {
                fill_value = (global_fill != "") ? global_fill : (i <= length(fill_arr) ? fill_arr[i] : "xxx")
                output = output (output ? " " : "") fill_value
            }
        }
        
        print output
    }' "$file")
    
    # Apply colors
    if [ "$has_header" = "true" ]; then
        local header_line=$(echo "$processed_data" | head -1)
        local data_lines=$(echo "$processed_data" | tail -n +2)
        
        echo -e "${light_green_color}${header_line}${end_color}"
        echo "$data_lines"
    else
        echo "$processed_data"
    fi
}


##
# Processes log files as space-separated, filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating if the file has a header row (default: true)
# @return Outputs the processed log file with empty fields filled
##
fill_empty_values_log() {
    local file="$1"                           # Store the input file path
    local num_columns="$2"                    # Store the number of columns
    local -n fill_array_ref="$3"              # Reference to the array of fill values
    local global_fill="${4:-}"                # Optional global fill value (default empty)
    local has_header="${5:-true}"             # Boolean indicating if file has a header (default true)
    
    local fill_array=("${fill_array_ref[@]}") # Copy the fill array from reference
    local fill_string="${fill_array[*]}"      # Convert fill array to space-separated string
    
    awk -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '  # Run awk without specific field separator
    BEGIN { split(fill_str, fill_arr, " ") } # Split fill string into array
    {
        if (has_header == "true" && NR == 1) { print; next }  # If header exists, print first line and skip
        output = ""                          # Initialize output string
        for (i=1; i<=NF; i++) {              # Loop through each field
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]  # Use global fill or array value
            if ($i == "") { output = output (output ? " " : "") fill_value }  # Fill empty field
            else { output = output (output ? " " : "") $i }  # Keep non-empty field
        }
        print output                         # Print processed line
    }' "$file"                               # Read input from file
}


##
# Processes fixed-width files (e.g., kubectl output), filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating if the file has a header row (default: true)
# @return Outputs the processed fixed-width file with empty fields filled
##
fill_empty_values_fixed() {
    local file="$1"                           # Store the input file path
    local num_columns="$2"                    # Store the number of columns
    local -n fill_array_ref="$3"              # Reference to the array of fill values
    local global_fill="${4:-}"                # Optional global fill value (default empty)
    local has_header="${5:-true}"             # Boolean indicating if file has a header (default true)
    
    local fill_array=("${fill_array_ref[@]}") # Copy the fill array from reference
    local header=$(head -1 "$file")           # Read the header line
    
    local positions=()                       # Initialize array for column positions
    positions[1]=1                           # Set first column position to 1
    for ((i=2; i<=num_columns; i++)); do      # Loop through columns to find positions
        positions[$i]=$(echo "$header" | awk -v col="$i" '{print index($0, $col)}')  # Calculate position of each column
    done
    
    local fill_string="${fill_array[*]}"      # Convert fill array to space-separated string
    local pos_string="${positions[*]}"        # Convert positions array to space-separated string
    
    # Process the file with awk and capture the output
    local processed_data
    processed_data=$(awk -v cols="$num_columns" -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" -v pos_str="$pos_string" '  # Run awk with variables
    BEGIN {
        split(fill_str, fill_arr, " ")        # Split fill string into array
        split(pos_str, pos_arr, " ")          # Split positions string into array
    }
    {
        if (has_header == "true" && NR == 1) {  # If header exists, print first line and skip
            print $0
            next
        }
        
        for (i=1; i<=cols; i++) {            # Loop through each column
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]  # Use global fill or array value
            
            start_pos = pos_arr[i]            # Get start position of column
            if (i < cols) {                   # Check if not the last column
                end_pos = pos_arr[i+1]        # Get end position from next column
            } else {
                end_pos = length($0) + 1      # Set end position to line length for last column
            }
            field_length = end_pos - start_pos  # Calculate field length
            
            original_field = substr($0, start_pos, field_length)  # Extract field content
            trimmed_field = original_field       # Copy field for trimming
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", trimmed_field)  # Trim leading/trailing spaces
            
            if (trimmed_field == "") {          # Check if field is empty
                printf "%s", fill_value         # Print fill value
                spaces_needed = field_length - length(fill_value)  # Calculate padding needed
                if (spaces_needed > 0) printf "%*s", spaces_needed, ""  # Add padding spaces
            } else {
                printf "%s", original_field     # Print original field
            }
        }
        printf "\n"                         # Print newline
    }' "$file")
    
    # Now apply colors to the processed data
    if [ "$has_header" = "true" ]; then
        # Extract header and colorize it
        local header_line=$(echo "$processed_data" | head -1)
        local data_lines=$(echo "$processed_data" | tail -n +2)
        
        echo -e "${yellow_color}${header_line}${end_color}"
        echo "$data_lines"
    else
        echo "$processed_data"
    fi
}



##
# Processes RFC 5424 syslog files, filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating if the file has a header row (default: true)
# @return Outputs the processed syslog file with empty fields filled
##
fill_empty_values_syslog() {
    local file="$1"                           # Store the input file path
    local num_columns="$2"                    # Store the number of columns
    local -n fill_array_ref="$3"              # Reference to the array of fill values
    local global_fill="${4:-}"                # Optional global fill value (default empty)
    local has_header="${5:-true}"             # Boolean indicating if file has a header (default true)
    
    local fill_array=("${fill_array_ref[@]}") # Copy the fill array from reference
    local fill_string="${fill_array[*]}"      # Convert fill array to space-separated string
    
    awk -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '  # Run awk with variables
    BEGIN {
        split(fill_str, fill_arr, " ")        # Split fill string into array
    }
    {
        if (has_header == "true" && NR == 1) {  # If header exists, print first line and skip
            print
            next
        }
        
        line = $0                            # Store current line
        output = ""                          # Initialize output string
        field_num = 1                        # Initialize field counter
        
        # Extract PRI+VERSION (first field, no space between them)
        if (match(line, /^<[0-9]+>[0-9]/)) {  # Check for PRI+VERSION pattern
            pri_version = substr(line, RSTART, RLENGTH)  # Extract PRI+VERSION
            line = substr(line, RSTART + RLENGTH)  # Remove extracted portion
            output = pri_version              # Set output to PRI+VERSION
            field_num++                       # Increment field counter
        } else {
            # Missing PRI+VERSION, fill it
            fill_value = (global_fill != "") ? global_fill : fill_arr[1]  # Use global fill or first array value
            output = fill_value               # Set output to fill value
            field_num++                       # Increment field counter
        }
        
        # Process next 5 fields (space-separated)
        for (; field_num <= 6; field_num++) {  # Loop through fields 2 to 6
            # Remove leading spaces
            sub(/^ /, "", line)               # Remove leading space from line
            
            if (line == "") break             # Exit loop if line is empty
            
            # Extract next field
            if (match(line, /^[^ ]+/)) {      # Check for next non-space field
                field_content = substr(line, RSTART, RLENGTH)  # Extract field content
                line = substr(line, RSTART + RLENGTH)  # Remove extracted portion
                
                if (field_content == "" || field_content == " ") {  # Check if field is empty
                    # Empty field, fill it
                    fill_value = (global_fill != "") ? global_fill : fill_arr[field_num]  # Use global fill or array value
                    output = output " " fill_value  # Append filled value
                } else {
                    output = output " " field_content  # Append field content
                }
            } else {
                # Missing field, fill it
                fill_value = (global_fill != "") ? global_fill : fill_arr[field_num]  # Use global fill or array value
                output = output " " fill_value  # Append filled value
            }
        }
        
        # Everything remaining is the MESSAGE - preserve all spaces
        sub(/^ /, "", line)                  # Remove leading space from remaining line
        if (line == "" || line == " ") {     # Check if message is empty
            message = (global_fill != "") ? global_fill : "No message"  # Use global fill or default message
        } else {
            message = line                    # Use remaining line as message
        }
        
        print output " " message             # Print processed line
    }' "$file"                               # Read input from file
}

##
# Processes traditional BSD syslog files, filling empty fields with specified values.
#
# @param file The input file path
# @param num_columns Number of columns in the file
# @param fill_array_ref Reference to an array of fill values for each column
# @param global_fill Optional global fill value to use for all empty fields
# @param has_header Boolean indicating if the file has a header row (default: true)
# @return Outputs the processed BSD syslog file with empty fields filled
##
fill_empty_values_bsdsyslog() {
    local file="$1"                           # Store the input file path
    local num_columns="$2"                    # Store the number of columns
    local -n fill_array_ref="$3"              # Reference to the array of fill values
    local global_fill="${4:-}"                # Optional global fill value (default empty)
    local has_header="${5:-true}"             # Boolean indicating if file has a header (default true)
    
    local fill_array=("${fill_array_ref[@]}") # Copy the fill array from reference
    local fill_string="${fill_array[*]}"      # Convert fill array to space-separated string
    
    # Use simple space separation for BSD syslog
    awk -v global_fill="$global_fill" -v has_header="$has_header" -v fill_str="$fill_string" '  # Run awk with variables
    BEGIN {
        split(fill_str, fill_arr, " ")        # Split fill string into array
    }
    {
        if (has_header == "true" && NR == 1) {  # If header exists, print first line and skip
            print
            next
        }
        
        output = ""                          # Initialize output string
        for (i=1; i<=NF; i++) {              # Loop through each field
            fill_value = (global_fill != "") ? global_fill : fill_arr[i]  # Use global fill or array value
            if ($i == "" || $i == ":") {     # Check if field is empty or a colon
                output = output (output ? " " : "") fill_value  # Fill empty field
            } else {
                output = output (output ? " " : "") $i  # Keep non-empty field
            }
        }
        print output                         # Print processed line
    }' "$file"                               # Read input from file
}

##
# Main execution block with POSIX-compliant argument parsing.
# Handles command-line options and processes the input file based on its detected format.
##
filename=""                                  # Initialize filename variable
fill_array=()                                # Initialize array for fill values
global_fill=""                               # Initialize global fill value
has_header="true"                            # Default to assuming header exists
pretty_print=false                           # Default to no pretty printing
use_stdin=false                              # Default to not using stdin

# First, check if any help option is requested
for arg in "$@"; do                          # Loop through command-line arguments
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then  # Check for help option
        echo "Usage: $0 [OPTIONS] [filename]" # Print usage information
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
        exit 0                                   # Exit after showing help
    fi
done

# Parse command line arguments
while [[ $# -gt 0 ]]; do        
        
    case "$1" in
        -c|--color)                      # Handle color option
            use_color=true
            ;;                 # Loop while there are arguments
        -f|--fill)                           # Handle fill option
            if [ $# -lt 2 ]; then            # Check if argument is provided
                echo "Error: Missing argument for $1" >&2  # Print error if missing
                exit 1
            fi
            shift                            # Shift to next argument
            fill_array=($1)                  # Store fill values in array
            ;;
        -g|--global)                         # Handle global fill option
            if [ $# -lt 2 ]; then            # Check if argument is provided
                echo "Error: Missing argument for $1" >&2  # Print error if missing
                exit 1
            fi
            shift                            # Shift to next argument
            global_fill="$1"                 # Store global fill value
            ;;
        -n|--no-header)                      # Handle no-header option
            has_header="false"               # Set header flag to false
            ;;
        -p|--pretty)                         # Handle pretty print option
            pretty_print=true                # Enable pretty printing
            ;;
        --)                                  # Handle end of options
            shift                            # Shift past --
            # Remaining arguments are treated as filenames
            while [[ $# -gt 0 ]]; do         # Loop through remaining arguments
                if [ -z "$filename" ]; then   # Check if filename is empty
                    filename="$1"            # Set filename
                else
                    echo "Error: Multiple filenames specified" >&2  # Print error for multiple filenames
                    exit 1
                fi
                shift                        # Shift to next argument
            done
            break                            # Exit loop
            ;;
        -)                                   # Handle explicit stdin indicator
            use_stdin=true                   # Enable stdin usage
            ;;
        -*)                                  # Handle combined short options and unknown options
            # Extract all characters after the dash
            options="${1:1}"                 # Get characters after dash
            # Process each character individually
            for (( i=0; i<${#options}; i++ )); do  # Loop through each character
                opt_char="${options:$i:1}"   # Get current option character
                case "$opt_char" in
                    h)                       # Handle help option
                        echo "Usage: $0 [OPTIONS] [filename]"  # Print usage information
                        echo "Options:"
                        echo "  -h, --help           Show this help message"
                        echo "  -f, --fill <values>   Fill values for empty fields (space-separated)"
                        echo "  -g, --global <value>  Global fill value for all empty fields"
                        echo "  -n, --no-header       Input file has no header row"
                        echo "  -p, --pretty          Pretty print output (pipe format only)"
                        exit 0               # Exit after showing help
                        ;;
                    f)                       # Handle fill option
                        if [ $# -lt 2 ]; then  # Check if argument is provided
                            echo "Error: Missing argument for -f" >&2  # Print error if missing
                            exit 1
                        fi
                        # Get the next argument for -f
                        fill_array=($2)      # Store fill values
                        # Skip the next argument since we consumed it
                        shift                # Shift to next argument
                        ;;
                    g)                       # Handle global fill option
                        if [ $# -lt 2 ]; then  # Check if argument is provided
                            echo "Error: Missing argument for -g" >&2  # Print error if missing
                            exit 1
                        fi
                        # Get the next argument for -g
                        global_fill="$2"     # Store global fill value
                        # Skip the next argument since we consumed it
                        shift                # Shift to next argument
                        ;;
                    n)                       # Handle no-header option
                        has_header="false"   # Set header flag to false
                        ;;
                    p)                       # Handle pretty print option
                        pretty_print=true    # Enable pretty printing
                        ;;
                    *)                       # Handle unknown option
                        echo "Error: Unknown option -$opt_char" >&2  # Print error for unknown option
                        echo "Use -h or --help for usage information" >&2
                        exit 1
                        ;;
                esac
            done
            ;;
        *)                                   # Handle filename argument
            if [ -z "$filename" ]; then       # Check if filename is empty
                filename="$1"                # Set filename
            else
                echo "Error: Multiple filenames specified: $filename and $1" >&2  # Print error for multiple filenames
                exit 1
            fi
            ;;
    esac
    shift                                    # Shift to next argument
done

# If color is disabled, reset all color variables to empty strings
if [ "$use_color" = false ]; then
    red_color=""
    end_color=""
    green_color=""
    blue_color=""
    yellow_color=""
    begin_color=""
    black_color=""
    dark_gray_color=""
    light_blue_color=""
    light_green_color=""
    cyan_color=""
    light_cyan_color=""
    light_red_color=""
    purple_color=""
    light_purple_color=""
    brown_color=""
    light_gray_color=""
    white_color=""
fi

# If no filename provided, use stdin
if [ -z "$filename" ]; then                  # Check if filename is empty
    use_stdin=true                           # Enable stdin usage
fi

# Handle stdin (either explicitly with - or implicitly when no filename)
if [ "$use_stdin" = true ] || [ "$filename" = "-" ]; then  # Check if using stdin
    # Create a temporary file for stdin content
    TEMP_FILE=$(mktemp)                      # Create temporary file
    cat > "$TEMP_FILE"                       # Write stdin to temporary file
    filename="$TEMP_FILE"                    # Set filename to temporary file
fi

# Check if file exists (unless it's stdin)
if [ ! -f "$filename" ]; then                # Check if file exists
    echo "Error: File $filename not found!" >&2  # Print error if file not found
    exit 1
fi

if [ ! -r "$filename" ]; then                # Check if file is readable
    echo "Error: File $filename is not readable" >&2  # Print error if not readable
    exit 1
fi

file_format=$(detect_file_format "$filename")  # Detect file format
echo "Detected format: $file_format" >&2      # Print detected format to stderr

# Process the file first, then apply pretty printing if requested
case "$file_format" in
    "csv")                                   # Handle CSV format
        col_count=$(head -1 "$filename" | awk -F, '{print NF}')  # Count columns in first line
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done  # Fill array with default values if needed
        echo "Processing as CSV with $col_count columns" >&2  # Print processing message
        processed_data=$(fill_empty_values_csv "$filename" "$col_count" fill_array "$global_fill" "$has_header")  # Process CSV file
        ;;
    "tsv")                                   # Handle TSV format
        col_count=$(head -1 "$filename" | awk -F$'\t' '{print NF}')  # Count columns in first line
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done  # Fill array with default values if needed
        echo "Processing as TSV with $col_count columns" >&2  # Print processing message
        processed_data=$(fill_empty_values_tsv "$filename" "$col_count" fill_array "$global_fill" "$has_header")  # Process TSV file
        ;;
    "semicolon")                             # Handle semicolon-separated format
        col_count=$(head -1 "$filename" | awk -F';' '{print NF}')  # Count columns in first line
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done  # Fill array with default values if needed
        echo "Processing as semicolon-separated with $col_count columns" >&2  # Print processing message
        processed_data=$(fill_empty_values_semicolon "$filename" "$col_count" fill_array "$global_fill" "$has_header")  # Process semicolon-separated file
        ;;
    "pipe")                                  # Handle pipe-separated format
        col_count=$(head -1 "$filename" | awk -F'|' '{print NF}')  # Count columns in first line
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done  # Fill array with default values if needed
        echo "Processing as pipe-separated with $col_count columns" >&2  # Print processing message
        processed_data=$(fill_empty_values_pipe "$filename" "$col_count" fill_array "$global_fill" "$has_header")  # Process pipe-separated file
        
        # Apply pretty printing after filling empty values
        if [ "$pretty_print" = true ]; then   # Check if pretty printing is enabled
            echo "Pretty printing pipe-separated data" >&2  # Print pretty printing message
            pretty_print_pipe "$processed_data" "$has_header"  # Pretty print the data
            exit 0                           # Exit after pretty printing
        fi
        ;;
    #"singlespace")                           # Handle single-space-separated format
    #    col_count=$(head -1 "$filename" | awk '{print NF}')  # Count columns in first line
    #    while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done  # Fill array with default values if needed
    #    echo "Processing as single-space-separated with $col_count columns" >&2  # Print processing message
    #    processed_data=$(fill_empty_values_singlespace "$filename" "$col_count" fill_array "$global_fill" "$has_header")  # Process single-space-separated file
    #    ;;
    # Simpler column count detection for single-space format
    # In the main script, improve the singlespace column count detection:
    "singlespace")                           # Handle single-space-separated format
        # More accurate column count detection that handles the header properly
        col_count=$(awk '
        NR == 1 {
            # Count fields in header, handling quoted values as separate fields
            gsub(/"[^"]*"/, "X", $0)  # Replace quoted sections with placeholder
            print NF
        }' "$filename")
        
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done
        echo "Processing as single-space-separated with $col_count columns" >&2
        processed_data=$(fill_empty_values_singlespace "$filename" "$col_count" fill_array "$global_fill" "$has_header")
        ;;
    "colon")                                 # Handle colon-separated format
        col_count=$(awk -F: '/^[-+=|[:space:]]*$/ { next } { gsub(/[^:]/, ""); fields = length($0) + 1; if (fields > max) max = fields } END { print (max > 0 ? max : 1) }' "$filename")  # Count max columns
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done  # Fill array with default values if needed
        echo "Processing as colon-separated with $col_count columns" >&2  # Print processing message
        processed_data=$(fill_empty_values_colon "$filename" "$col_count" fill_array "$global_fill" "$has_header")  # Process colon-separated file
        ;;
    "syslog")                                # Handle RFC 5424 syslog format
        col_count=7                          # Set fixed column count for syslog
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done  # Fill array with default values if needed
        echo "Processing as RFC 5424 syslog with $col_count columns" >&2  # Print processing message
        processed_data=$(fill_empty_values_syslog "$filename" "$col_count" fill_array "$global_fill" "$has_header")  # Process syslog file
        ;;
    "bsdsyslog")                             # Handle BSD syslog format
        col_count=6                          # Set fixed column count for BSD syslog
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done  # Fill array with default values if needed
        echo "Processing as BSD syslog with $col_count columns" >&2  # Print processing message
        processed_data=$(fill_empty_values_bsdsyslog "$filename" "$col_count" fill_array "$global_fill" "$has_header")  # Process BSD syslog file
        ;;
    "weblog"|"applog"|"jsonlog")             # Handle web log, app log, or JSON log
        col_count=$(head -1 "$filename" | awk '{print NF}')  # Count columns in first line
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done  # Fill array with default values if needed
        echo "Processing $file_format as space-separated with $col_count columns" >&2  # Print processing message
        processed_data=$(fill_empty_values_log "$filename" "$col_count" fill_array "$global_fill" "$has_header")  # Process as space-separated log
        ;;
    *)                                       # Handle unknown or fixed-width format
        col_count=$(head -1 "$filename" | awk '{print NF}')  # Count columns in first line
        while [ ${#fill_array[@]} -lt "$col_count" ]; do fill_array+=("xxx"); done  # Fill array with default values if needed
        echo "Processing as fixed-width with $col_count columns" >&2  # Print processing message
        processed_data=$(fill_empty_values_fixed "$filename" "$col_count" fill_array "$global_fill" "$has_header")  # Process as fixed-width file
        ;;
esac

# Output the processed data (unless pretty print was already handled in pipe case)
echo "$processed_data"                       # Print the processed data

# Clean up temporary file if we used stdin
if [ "$use_stdin" = true ] || [ "$filename" = "-" ]; then
    rm -f "$TEMP_FILE"
fi
