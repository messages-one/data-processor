#!/bin/bash
# test_weblog_format.sh - Test web server log format detection and processing

echo "=== Testing Web Server Log Format ==="
echo

# Create test files for different web server log formats
create_test_files() {
    echo "Creating web server log test files..."
    
    # NGINX access log format (common)
    cat > test_nginx.log << EOF
192.168.1.1 - - [15/Jan/2023:10:30:00 +0000] "GET /api/users HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
192.168.1.2 - john [15/Jan/2023:10:31:00 +0000] "POST /api/login HTTP/1.1" 401 567 "-" "curl/7.68.0"
192.168.1.3 - - [15/Jan/2023:10:32:00 +0000] "GET /static/css/style.css HTTP/1.1" 304 0 "https://example.com" "Mozilla/5.0"
127.0.0.1 - admin [15/Jan/2023:10:33:00 +0000] "PUT /api/settings HTTP/1.1" 500 789 "https://admin.example.com" "Python-urllib/3.8"
EOF

    # Apache access log format (combined)
    cat > test_apache.log << EOF
192.168.1.100 - - [15/Jan/2023:10:34:00 +0000] "GET /index.html HTTP/1.1" 200 2326 "https://www.google.com/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
10.0.0.1 - jane [15/Jan/2023:10:35:00 +0000] "POST /api/upload HTTP/1.1" 201 1024 "https://example.com/upload" "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
172.16.0.1 - - [15/Jan/2023:10:36:00 +0000] "GET /robots.txt HTTP/1.1" 404 287 "-" "Googlebot/2.1"
EOF

    # Log with some missing fields (real-world scenario)
    cat > test_weblog_missing.log << EOF
192.168.1.1 - - [15/Jan/2023:10:30:00 +0000] "GET /api/users HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
 - - [15/Jan/2023:10:31:00 +0000] "POST /api/login HTTP/1.1" 401 567 "-" "curl/7.68.0"
192.168.1.3 - - [15/Jan/2023:10:32:00 +0000] "GET /static/css/style.css HTTP/1.1"  0 "https://example.com" "Mozilla/5.0"
127.0.0.1 - admin [15/Jan/2023:10:33:00 +0000] "PUT /api/settings HTTP/1.1" 500  "https://admin.example.com" "Python-urllib/3.8"
EOF

    echo "Web server log test files created!"
}

test_weblog_detection() {
    echo "1. Testing NGINX log detection:"
    ./complete.sh test_nginx.log 2>&1 | grep "Detected format"
    echo

    echo "2. Testing Apache log detection:"
    ./complete.sh test_apache.log 2>&1 | grep "Detected format"
    echo

    echo "3. Testing log with missing fields detection:"
    ./complete.sh test_weblog_missing.log 2>&1 | grep "Detected format"
    echo
}

test_weblog_processing() {
    echo "4. Testing NGINX log processing (should show original lines):"
    ./complete.sh test_nginx.log -n  # no header
    echo

    echo "5. Testing Apache log processing (should show original lines):"
    ./complete.sh test_apache.log -n  # no header
    echo

    echo "6. Testing log with missing fields processing:"
    echo "   Before (lines with missing fields):"
    grep -E "( - \[|  [0-9]{3}  |  [0-9]{3} $)" test_weblog_missing.log
    echo "   After (with global fill):"
    ./complete.sh test_weblog_missing.log -g "MISSING" -n | grep -E "(MISSING| - \[|  [0-9]{3}  |  [0-9]{3} $)"
    echo
}

test_weblog_variations() {
    # Test different log format variations
    echo "7. Testing various web log format detection:"
    
    # Common log format
    echo "common.log:192.168.1.1 - - [15/Jan/2023:10:30:00 +0000] \"GET / HTTP/1.1\" 200 1234" > test_common.log
    echo "   Common format: $(./complete.sh test_common.log 2>&1 | grep 'Detected format')"
    
    # Log with IPv6
    echo "ipv6.log:2001:db8::1 - - [15/Jan/2023:10:30:00 +0000] \"GET / HTTP/1.1\" 200 1234" > test_ipv6.log
    echo "   IPv6 format: $(./complete.sh test_ipv6.log 2>&1 | grep 'Detected format')"
    
    # Log with different time format
    echo "timeformat.log:192.168.1.1 - - [2023-01-15T10:30:00+00:00] \"GET / HTTP/1.1\" 200 1234" > test_timeformat.log
    echo "   Different time: $(./complete.sh test_timeformat.log 2>&1 | grep 'Detected format')"
    
    rm -f test_common.log test_ipv6.log test_timeformat.log
    echo
}

cleanup() {
    rm -f test_nginx.log test_apache.log test_weblog_missing.log
    echo "Test files cleaned up!"
}

# Main execution
echo "Creating web server log test files..."
create_test_files
echo

echo "Testing web log format detection..."
test_weblog_detection

echo "Testing web log processing..."
test_weblog_processing

echo "Testing web log variations..."
test_weblog_variations

echo "Cleaning up..."
cleanup

echo
echo "=== Web Server Log Test Complete ==="
