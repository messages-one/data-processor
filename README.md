

Data Format Processor: The Ultimate Swiss Army Knife for Data Cleaning and Formatting
=====================================================================================


![alt text](image.png)

📋 Introduction
---------------

In the world of data processing, we often encounter files with inconsistent formatting, missing values, and various delimiters. Whether you're dealing with CSV files, log files, database exports, or system files, maintaining clean and consistent data is crucial for accurate analysis and processing.

The **Data Format Processor** is a powerful Bash-based tool that automates the detection and processing of over 10 different file formats while handling missing or empty fields intelligently. After extensive development and testing, we're excited to share this open-source solution with the community.

✨ Key Features
--------------

### 🎯 Automatic Format Detection

*   **CSV/TSV**: Comma and tab-separated values
    
*   **Colon-separated**: /etc/passwd style files
    
*   **Pipe-separated**: Vertical bar delimited files
    
*   **Web server logs**: NGINX, Apache, and common log formats
    
*   **JSON logs**: Structured log files
    
*   **Syslog formats**: Both RFC 5424 and traditional BSD syslog
    
*   **Fixed-width**: Kubectl-style output and multi-space files
    
*   **Single-space**: Space-separated values
    

### 🔧 Intelligent Processing

*   **Smart empty field detection**: Identifies missing values automatically
    
*   **Configurable fill values**: Per-column or global fill values
    
*   **Header awareness**: Respects or ignores header rows as needed
    
*   **Format preservation**: Maintains original structure while filling gaps
    

### 🎨 Pretty Printing

*   **Beautiful formatting**: Aligned columns with proper spacing
    
*   **Visual separators**: Clean header/data separation
    
*   **Smart alignment**: Right-aligned numbers, left-aligned text
    
*   **Border formatting**: Professional table-like output
    

🚀 Installation
---------------

    # Clone the repository
    git clone https://github.com/yourusername/data-format-processor.git
    cd data-format-processor
    
    # Make the script executable
    chmod +x complete.sh
    
    # Optional: Add to your PATH
    sudo cp complete.sh /usr/local/bin/dfp

📖 Basic Usage
--------------

    # Basic usage with automatic detection
    ./complete.sh filename.txt
    
    # With custom fill values
    ./complete.sh data.csv -f "Unknown 0 N/A"
    
    # Global fill value for all empty fields
    ./complete.sh data.txt -g "MISSING"
    
    # No header row and pretty print
    ./complete.sh data.pipe -n -p

🎪 Real-World Examples
----------------------

### Example 1: Processing System Files

    # Clean /etc/passwd style files
    ./complete.sh users.txt -f "default_password 0 0 Unknown /home/default /bin/bash" -n
    
    # Input:
    # john::1001:1001:John Doe:/home/john:/bin/bash
    # jane:x:1002:1002::/home/jane:
    
    # Output:
    # john:default_password:1001:1001:John Doe:/home/john:/bin/bash
    # jane:x:1002:1002:Unknown:/home/jane:default_password

### Example 2: Web Server Log Maintenance

    # Process NGINX logs with missing fields
    ./complete.sh access.log -g "NULL" -n
    
    # Input line with missing IP:
    #  - - [15/Jan/2023:10:31:00 +0000] "POST /api/login HTTP/1.1" 401 567 "-" "curl/7.68.0"
    
    # Output:
    # NULL - - [15/Jan/2023:10:31:00 +0000] "POST /api/login HTTP/1.1" 401 567 "-" "curl/7.68.0"

### Example 3: Database Export Processing

    # Process CSV exports with pretty printing
    ./complete.sh export.csv -f "N/A 0 0000-00-00 pending" -p
    
    # Input:
    # ID,Name,Age,JoinDate,Status
    # 1,John,25,2020-01-15,Active
    # 2,Jane,,2019-08-22,
    # 3,Bob,35,,Inactive
    
    # Output (pretty printed):
    # | ID | Name | Age | JoinDate     | Status   |
    # +----+------+-----+--------------+----------+
    # | 1  | John | 25  | 2020-01-15   | Active   |
    # | 2  | Jane | N/A | 2019-08-22   | pending  |
    # | 3  | Bob  | 35  | 0000-00-00   | Inactive |

### Example 4: Kubernetes Output Formatting

    # Pretty print kubectl output
    kubectl get pods | ./complete.sh - -n -p
    
    # Input (multi-space):
    # NAME      AGE  STATUS    RESTARTS
    # web-app   2d   Running   0
    # db-pod     Running      3
    
    # Output (aligned):
    # | NAME    | AGE | STATUS  | RESTARTS |
    # +---------+-----+---------+----------+
    # | web-app | 2d  | Running | 0        |
    # | db-pod  |     | Running | 3        |

⚙️ Advanced Usage
-----------------

### Custom Fill Arrays

    # Different fill values for each column
    ./complete.sh data.csv -f "Unknown 0 N/A 0000-00-00 pending"
    
    # Column mapping:
    # 1: "Unknown" (for names)
    # 2: "0"        (for ages)
    # 3: "N/A"      (for departments)
    # 4: "0000-00-00" (for dates)
    # 5: "pending"   (for status)

### Integration with Data Pipelines

    # Process multiple files in a pipeline
    find /var/log -name "*.log" -exec ./complete.sh {} -g "NULL" \; > processed.log
    
    # Combine with other tools
    ./complete.sh data.csv -f "0 N/A" | awk '{print $1,$3}' | sort -n
    
    # Use in CI/CD pipelines
    kubectl get deployments | ./complete.sh - -n -p | mail -s "K8s Status" admin@example.com

### Batch Processing

    # Process all files in a directory
    for file in /data/*.{csv,txt,log}; do
        ./complete.sh "$file" -g "MISSING" -n > "/processed/$(basename "$file")"
    done

🏗️ Architecture & Design
-------------------------

### Smart Detection Algorithm

The processor uses a multi-layered detection approach:

1.  **Priority-based checking**: Specialized formats first (syslog, JSON)
    
2.  **Pattern matching**: Regex patterns for each format type
    
3.  **Fallback handling**: Fixed-width as default catch-all
    
4.  **Multi-sample verification**: Checks multiple lines for consistency
    

### Modular Processing Functions

Each format has dedicated processing functions:

*   `fill_empty_values_csv()` for comma-separated files
    
*   `fill_empty_values_colon()` for colon-separated files
    
*   `fill_empty_values_pipe()` for pipe-separated files
    
*   `pretty_print_pipe()` for beautiful formatting
    

🔍 Technical Details
--------------------

### Supported Formats

| Format | Detection Pattern | Typical Use Cases |
| --- | --- | --- |
| CSV | `,` delimiter with multiple fields | Data exports, spreadsheets |
| TSV | `\t` delimiter | Database exports, scientific data |
| Pipe | `|` delimiter with multiple fields | Configuration files, reports |
| Colon | `:` delimiter with 2+ fields | /etc/passwd, system files |
| JSON | Lines starting with `{` | Log files, API responses |
| Web Log | IP + HTTP + status code pattern | NGINX, Apache access logs |
| Syslog | RFC 5424 header pattern | System logging |

### Performance Characteristics

*   **Lightweight**: Pure Bash implementation, no dependencies
    
*   **Fast processing**: Stream-based processing handles large files
    
*   **Low memory**: Processes files line by line
    
*   **Efficient**: Smart detection avoids unnecessary processing
    

🌟 Benefits & Advantages
------------------------

### For System Administrators

*   **Log file maintenance**: Clean and standardize log files
    
*   **Configuration management**: Process system files consistently
    
*   **Automation ready**: Integrates with existing shell scripts
    

### For Data Engineers

*   **Data cleaning**: Prepare files for analysis and processing
    
*   **Format conversion**: Standardize various input formats
    
*   **Pipeline integration**: Works with existing data workflows
    

### For Developers

*   **Debugging aid**: Clean and format diagnostic output
    
*   **Testing**: Create consistent test data files
    
*   **Documentation**: Generate pretty-printed reports
    

📊 Comparison with Other Tools
------------------------------

| Feature | Data Format Processor | awk/sed | Specialized Tools |
| --- | --- | --- | --- |
| **Automatic detection** | ✅ | ❌ | ❌ |
| **Multiple formats** | ✅ | ⚠️ | ❌ |
| **Pretty printing** | ✅ | ❌ | ⚠️ |
| **No dependencies** | ✅ | ✅ | ❌ |
| **Easy to use** | ✅ | ⚠️ | ⚠️ |

🚦 Getting Started Guide
------------------------

### Step 1: Identify Your Data

    # Check what format your file is
    head -n 3 yourfile.txt

### Step 2: Choose Processing Options

    # For files with headers (default)
    ./complete.sh yourfile.txt
    
    # For files without headers
    ./complete.sh yourfile.txt -n
    
    # For specific fill values
    ./complete.sh yourfile.txt -f "Unknown 0 N/A"
    
    # For pretty printing (pipe format only)
    ./complete.sh yourfile.txt -p

### Step 3: Verify Results

    # Check first few lines of output
    ./complete.sh yourfile.txt | head -n 5
    
    # Compare before/after
    echo "=== BEFORE ==="
    head -n 3 yourfile.txt
    echo "=== AFTER ==="
    ./complete.sh yourfile.txt | head -n 3

    

🤝 Contributing
---------------

We welcome contributions from the community! Areas where you can help:

*   **New format detectors**: Add support for additional file formats
    
*   **Performance optimization**: Improve processing speed and memory usage
    
*   **Documentation**: Enhance examples and use cases
    
*   **Testing**: Expand test coverage and edge cases
    


Running the tests

  ./test-script.sh

  ./test-web-logs.sh





Data Format Processor: Complete Command Line Reference Guide
============================================================

📋 Overview
-----------

The Data Format Processor supports a comprehensive set of command-line arguments following POSIX standards. Here's the complete reference:

🎯 Basic Syntax
---------------

    ./complete.sh [OPTIONS] <filename>

🔧 Argument Reference
---------------------

### 📁 Filename (Required)

*   **Description**: Input file to process
    
*   **Position**: First non-option argument or after `--`
    
*   **Special values**:
    
    *   `-` : Read from standard input
        
*   **Examples**:
    
        ./complete.sh data.csv              # Regular file
        ./complete.sh -                     # Read from stdin
        cat data.txt | ./complete.sh -      # Pipeline input
    

### 🎨 Format Options

#### `-f, --fill <values>`

*   **Description**: Space-separated fill values for empty fields
    
*   **Usage**: Different value for each column position
    
*   **Examples**:
    
        -f "Unknown 0 N/A"          # Column 1: "Unknown", Column 2: "0", Column 3: "N/A"
        -f "default EMPTY 0000-00-00 pending"
    

#### `-g, --global <value>`

*   **Description**: Single fill value for all empty fields
    
*   **Usage**: Overrides `--fill` if both specified
    
*   **Examples**:
    
        -g "MISSING"                # All empty fields become "MISSING"
        -g "NULL"                   # All empty fields become "NULL"
        -g "0"                      # All empty fields become "0"
    

#### `-n, --no-header`

*   **Description**: Input file has no header row
    
*   **Usage**: Treat first line as data, not headers
    
*   **Examples**:
    
        -n                          # No header row
        --no-header                 # Long form
    

#### `-p, --pretty`

*   **Description**: Pretty print output (pipe format only)
    
*   **Usage**: Creates aligned columns with visual separators
    
*   **Examples**:
    
        -p                          # Enable pretty printing
        --pretty                    # Long form
    

#### `-h, --help`

*   **Description**: Show help message and exit
    
*   **Usage**: Display usage information
    
*   **Examples**:
    
        -h                          # Show help
        --help                      # Long form
    

🔄 Argument Combinations
------------------------

### Basic Combinations

#### 1\. **Simple Processing**

    # Basic file processing
    ./complete.sh filename.txt
    
    # Process stdin
    cat data.txt | ./complete.sh -
    
    # With explicit filename
    ./complete.sh -- filename-with-dashes.txt

#### 2\. **Fill Value Combinations**

    # Per-column fill values
    ./complete.sh data.csv -f "Unknown 0 N/A 0000-00-00"
    
    # Global fill value
    ./complete.sh data.txt -g "MISSING"
    
    # Mixed: global overrides per-column
    ./complete.sh data.csv -f "A B C" -g "OVERRIDE"  # All empty fields become "OVERRIDE"

#### 3\. **Header Control Combinations**

    # With header (default)
    ./complete.sh data.csv
    
    # Without header
    ./complete.sh data.csv -n
    
    # No header with fill values
    ./complete.sh data.csv -n -f "Unknown 0"

#### 4\. **Pretty Print Combinations**

    # Pretty print with headers
    ./complete.sh data.pipe -p
    
    # Pretty print without headers
    ./complete.sh data.pipe -n -p
    
    # Pretty print with custom fill values
    ./complete.sh data.pipe -f "Unknown 0" -p

### Advanced Combinations

#### 5\. **Combined Short Options**

    # Combined flags (order doesn't matter)
    ./complete.sh data.pipe -fnp "Unknown 0"   # -f -n -p
    ./complete.sh data.csv -ng "MISSING"       # -n -g
    ./complete.sh data.txt -pn                 # -p -n

#### 6\. **Mixed Short and Long Options**

    # Mixed short and long options
    ./complete.sh data.pipe -f "Unknown 0" --pretty
    ./complete.sh data.csv --no-header -g "NULL"
    ./complete.sh data.txt --fill "A B C" -n

#### 7\. **File Position Variations**

    # Filename first (backward compatible)
    ./complete.sh data.txt -f "Unknown 0" -n
    
    # Options first (POSIX standard)
    ./complete.sh -f "Unknown 0" -n data.txt
    
    # Filename in the middle
    ./complete.sh -f "Unknown 0" data.txt -n
    
    # Using -- to separate options from filename
    ./complete.sh -f "Unknown 0" -n -- data.txt

#### 8\. **Pipeline Integration**

    # Process command output
    kubectl get pods | ./complete.sh - -n -p
    
    # Process filtered content
    grep "ERROR" app.log | ./complete.sh - -g "CRITICAL"
    
    # Multiple processing steps
    cat data.csv | ./complete.sh - -f "0 N/A" | sort | head -10

🎯 Format-Specific Examples
---------------------------

### CSV Files

    # Basic CSV processing
    ./complete.sh data.csv
    
    # CSV with custom fill values
    ./complete.sh data.csv -f "Unknown 0 0000-00-00 N/A"
    
    # CSV without header
    ./complete.sh data.csv -n -g "MISSING"

### Pipe-Separated Files

    # Pretty print pipe files
    ./complete.sh data.pipe -p
    
    # Pipe file with no header and fill values
    ./complete.sh data.pipe -n -f "Unknown 0" -p
    
    # Global fill for pipe files
    ./complete.sh data.pipe -g "NULL" -p

### Colon-Separated Files (/etc/passwd style)

    # Process colon-separated files
    ./complete.sh passwd.txt -f "x 0 0 Unknown /home/user /bin/bash"
    
    # With global fill
    ./complete.sh passwd.txt -g "DEFAULT" -n

### Log Files

    # Web server logs
    ./complete.sh access.log -g "NULL" -n
    
    # JSON logs (treated as space-separated)
    ./complete.sh app.log -f "\"NULL\" \"MISSING\"" -n

### Fixed-Width Files (kubectl output)

    # Process kubectl output
    kubectl get pods | ./complete.sh - -n -f "Unknown Running 0"
    
    # With pretty printing
    kubectl get nodes | ./complete.sh - -n -p

🔧 Special Cases and Edge Handling
----------------------------------

### Empty Argument Handling

    # Empty fill array
    ./complete.sh data.txt -f ""          # Uses default "xxx" for empty fields
    
    # Empty global value
    ./complete.sh data.txt -g ""          # Uses empty string for filling
    
    # No fill values specified
    ./complete.sh data.txt                # Uses default "xxx" for empty fields

### Error Handling

    # Missing filename
    ./complete.sh                         # Error: Filename required
    
    # File not found
    ./complete.sh nonexistent.txt         # Error: File not found
    
    # Missing argument for option
    ./complete.sh data.txt -f             # Error: Missing argument for -f
    
    # Unknown option
    ./complete.sh data.txt -x             # Error: Unknown option -x

### Default Behavior

    # Default fill value: "xxx"
    ./complete.sh data.txt                # Empty fields become "xxx"
    
    # Default has_header: true
    ./complete.sh data.txt                # First line treated as header
    
    # Default pretty_print: false
    ./complete.sh data.pipe               # No pretty printing

🚀 Real-World Use Case Combinations
-----------------------------------

### Database Export Processing

    # Process CSV export with specific defaults
    ./complete.sh export.csv -f "0 Unknown 0000-00-00 pending" -n
    
    # With global override
    ./complete.sh export.csv -f "A B C" -g "MISSING_DATA" -n

### Log File Analysis

    # Process web logs with null placeholders
    ./complete.sh access.log -g "NULL" -n | grep "ERROR"
    
    # JSON log processing
    ./complete.sh app.log -f "\"NULL\" \"UNKNOWN\"" -n | jq .

### Kubernetes Operations

    # Pretty print kubectl output
    kubectl get pods -A | ./complete.sh - -n -p
    
    # Process with custom fill values
    kubectl get nodes | ./complete.sh - -n -f "Unknown Ready 0" -p
    
    # Environment variable processing
    kubectl describe pod my-pod | grep "Environment:" | ./complete.sh - -n -f "default_value"

### Configuration File Processing

    # Process .env files
    ./complete.sh .env -f "default_value" -n
    
    # Process properties files
    ./complete.sh application.properties -f "default" -n
    
    # Process INI files (as colon-separated)
    ./complete.sh config.ini -f "default_value" -n

📋 Argument Precedence Rules
----------------------------

1.  **Help option**: `-h` or `--help` shows help and exits immediately
    
2.  **Global vs Per-column**: `-g` overrides `-f` if both specified
    
3.  **Header default**: `has_header=true` unless `-n` or `--no-header` specified
    
4.  **Filename position**: Can be anywhere except between option and its argument
    
5.  **Combined options**: `-fnp` equivalent to `-f -n -p`
    

🎯 Summary Table
----------------

| Option | Short | Long | Argument | Description | Default |
| --- | --- | --- | --- | --- | --- |
| Help | `-h` | `--help` | None | Show help | \- |
| Fill | `-f` | `--fill` | Values | Per-column fill | `"xxx"` |
| Global | `-g` | `--global` | Value | Global fill | \- |
| No Header | `-n` | `--no-header` | None | No header row | `false` |
| Pretty | `-p` | `--pretty` | None | Pretty print | `false` |
| Filename | \- | \- | Path | Input file | Required |

This comprehensive argument system provides flexibility for all use cases while maintaining POSIX compliance and intuitive usage!

---








🎉 Conclusion
-------------

The Data Format Processor represents a significant advancement in command-line data processing tools. By combining intelligent format detection with robust empty field handling and beautiful pretty printing, it solves real-world problems that developers, sysadmins, and data engineers face daily.

Whether you're cleaning log files, processing system outputs, or preparing data for analysis, this tool provides a consistent, reliable, and efficient solution.

**Try it today and experience the difference in your data processing workflows!**

* * *

_This tool is the result of extensive testing and refinement. We're excited to see how the community will use and extend it for their specific needs. Happy data processing!_ 🚀

---

