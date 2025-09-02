#!/bin/bash
# test_empty_filling_renewed.sh - Test script focused on empty field filling with new argument parsing

echo "=== Testing Empty Field Filling with New POSIX Argument Parsing ==="
echo

# Create test files with missing/empty fields including JSON
create_test_files() {
    echo "Creating test files with empty fields including JSON..."
    
    # CSV with various empty fields
    cat > test_csv.csv << EOF
ID,Name,Department,Salary,StartDate,Status
1,John,Engineering,75000,2020-01-15,Active
2,Jane,Marketing,,2019-08-22,
3,Bob,,68000,2021-03-10,Inactive
4,Alice,HR,65000,,Active
5,Charlie,IT,,2020-11-30,
6,,Sales,72000,2022-05-15,Pending
EOF

    # Single-space separated with empty fields
    cat > test_single_space.txt << EOF
ID Name Department Salary StartDate Status
1 John Engineering 75000 2020-01-15 Active
2 Jane Marketing  2019-08-22 
3 Bob  68000 2021-03-10 Inactive
4 Alice HR 65000  Active
5 Charlie IT  2020-11-30 
6  Sales 72000 2022-05-15 Pending
EOF

    # Colon-separated with empty fields (like /etc/passwd style)
    cat > test_colon.txt << EOF
username:password:uid:gid:gecos:home:shell
root:x:0:0:root:/root:/bin/bash
john::1001:1001:John Doe:/home/john:/bin/bash
jane:x:1002:1002::/home/jane:
bob:x:1003:1003:Bob Smith::/bin/bash
::1004:1004:Test User:/home/test:/bin/bash
EOF

    # Pipe-separated with empty fields
    cat > test_pipe.txt << EOF
Name|Age|City|Salary|Department|Status
John Doe|25|New York|75000|Engineering|Active
Jane Smith||London||Marketing|
Bob Johnson|35||55000|Sales|Inactive
|28|Paris|48000||Active
Charlie Brown|42|Tokyo||IT|Pending
|||72000|HR|
EOF

    # Multi-space (kubectl style) with empty fields
    cat > test_multispace.txt << EOF
NAME      AGE  CITY        SALARY    DEPARTMENT  STATUS
John      25   New York    75000     Engineering Active
Jane               London            Marketing  
Bob       35                55000    Sales       Inactive
          28   Paris       48000                 Active
Charlie   42   Tokyo                 IT          Pending
                    72000   HR       
EOF

    # JSON log format with missing fields
    cat > test_json.log << EOF
{"timestamp":"2023-01-15T10:30:00Z","level":"INFO","message":"User logged in","user_id":123,"ip":"192.168.1.1"}
{"timestamp":"2023-01-15T10:31:00Z","level":"ERROR","message":"Database connection failed","user_id":,"ip":""}
{"timestamp":"2023-01-15T10:32:00Z","level":"WARN","message":"","user_id":456,"ip":"192.168.1.2"}
{"timestamp":"2023-01-15T10:33:00Z","level":"INFO","message":"File uploaded","user_id":789,"ip":}
{"level":"DEBUG","message":"Cache cleared","user_id":101,"ip":"192.168.1.3"}
{"timestamp":"2023-01-15T10:35:00Z","message":"Payment processed","user_id":202,"ip":"192.168.1.4"}
EOF

    echo "Test files created with empty fields including JSON!"
}

run_empty_filling_tests() {
    echo "1. Testing CSV with new argument parsing:"
    echo "   Before:"
    grep -E "(2|3|4|6)" test_csv.csv
    echo "   After:"
    ./complete.sh test_csv.csv -f "Unknown EMPTY 0 0000-00-00 NULL" | grep -E "(2|3|4|6)"
    echo

    echo "2. Testing Single-space with new argument parsing:"
    echo "   Before:"
    grep -E "(2|3|4|6)" test_single_space.txt
    echo "   After:"
    ./complete.sh test_single_space.txt -f "Unknown EMPTY 0 0000-00-00 NULL" | grep -E "(2|3|4|6)"
    echo

    echo "3. Testing Colon-separated with new argument parsing:"
    echo "   Before:"
    grep -E "(john|jane|bob|1004)" test_colon.txt
    echo "   After:"
    ./complete.sh test_colon.txt -f "default_password 0 0 Empty /home/default /bin/bash" | grep -E "(john|jane|bob|1004)"
    echo

    echo "4. Testing Pipe-separated with new argument parsing:"
    echo "   Before:"
    grep -E "(Jane|Bob|28|Charlie|72000)" test_pipe.txt
    echo "   After:"
    ./complete.sh test_pipe.txt -f "Unknown 0 Unknown 0 Unknown EMPTY" | grep -E "(Jane|Bob|28|Charlie|72000)"
    echo

    echo "5. Testing Multi-space (kubectl) with new argument parsing:"
    echo "   Before:"
    grep -E "(Jane|Bob|28|Charlie|72000)" test_multispace.txt
    echo "   After:"
    ./complete.sh test_multispace.txt -f "Unknown 0 Unknown 0 Unknown EMPTY" | grep -E "(Jane|Bob|28|Charlie|72000)"
    echo

    echo "6. Testing JSON format with new argument parsing:"
    echo "   Before (showing lines with missing data):"
    grep -E "(\"user_id\":,|\"message\":\"\"|\"ip\":}|\"timestamp\":\"[^\"]*\"[^,]*$)" test_json.log
    echo "   After:"
    ./complete.sh test_json.log -f "\"NULL\" \"MISSING\" \"unknown\"" -n | grep -E "(\"user_id\":,|\"message\":\"\"|\"ip\":}|\"timestamp\":\"[^\"]*\"[^,]*$)"
    echo

    echo "7. Testing Global Fill Value with new argument parsing:"
    echo "   CSV with global fill:"
    ./complete.sh test_csv.csv -g "xxx" | grep -E "(2|3|4|6)"
    echo
}

test_pretty_print() {
    echo "8. Testing Pretty Print for Pipe-separated with new argument parsing:"
    echo "   Original:"
    head -3 test_pipe.txt
    echo "   Pretty Printed:"
    ./complete.sh test_pipe.txt -f "Unknown 0 Unknown 0 Unknown EMPTY" -p | head -5
    echo

    echo "9. Testing Pretty Print with Global Fill and no-header:"
    ./complete.sh test_pipe.txt -g "MISSING" -n -p | head -5
    echo
}

test_detection() {
    echo "10. Format Detection Test with new argument parsing:"
    echo "   CSV: $(./complete.sh test_csv.csv 2>&1 | grep 'Detected format')"
    echo "   Single-space: $(./complete.sh test_single_space.txt 2>&1 | grep 'Detected format')"
    echo "   Colon: $(./complete.sh test_colon.txt 2>&1 | grep 'Detected format')"
    echo "   Pipe: $(./complete.sh test_pipe.txt 2>&1 | grep 'Detected format')"
    echo "   Multi-space: $(./complete.sh test_multispace.txt 2>&1 | grep 'Detected format')"
    echo "   JSON: $(./complete.sh test_json.log -n 2>&1 | grep 'Detected format')"
    echo
}

test_argument_parsing() {
    echo "11. Testing various argument parsing combinations:"
    
    echo "   a) Combined short options:"
    ./complete.sh test_pipe.txt -fnp "Unknown 0 Unknown 0 Unknown EMPTY" 2>&1 | grep "Processing"
    echo
    
    echo "   b) Separate options:"
    ./complete.sh test_csv.csv -f "Unknown EMPTY" -n -g "GLOBAL" 2>&1 | grep "Processing"
    echo
    
    echo "   c) Long options:"
    ./complete.sh test_colon.txt --fill "default_password 0 0" --no-header 2>&1 | grep "Processing"
    echo
    
    echo "   d) Help option:"
    ./complete.sh --help | head -5
    echo
}

cleanup() {
    rm -f test_*
    echo "Test files cleaned up!"
}

# Main execution
echo "Creating test files with empty fields including JSON..."
create_test_files
echo

echo "Running empty field filling tests with new argument parsing..."
run_empty_filling_tests

echo "Testing pretty print functionality..."
test_pretty_print

echo "Testing format detection..."
test_detection

echo "Testing argument parsing combinations..."
test_argument_parsing

echo "Cleaning up..."
cleanup

echo
echo "=== Empty Field Filling Test Complete ==="
echo "All tests completed with new POSIX argument parsing!"