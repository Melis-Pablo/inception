<?php
// This file is for debugging environment variables in PHP

// Header for plain text output
header('Content-Type: text/plain');

echo "===== PHP Environment Variables Test =====\n\n";

// Function to check environment variable with multiple methods
function check_env_var($name) {
    echo "Variable: $name\n";
    
    // Method 1: getenv()
    echo "  getenv(): " . (getenv($name) ?: 'NOT FOUND') . "\n";
    
    // Method 2: $_ENV superglobal
    echo "  \$_ENV: " . (isset($_ENV[$name]) ? $_ENV[$name] : 'NOT FOUND') . "\n";
    
    // Method 3: $_SERVER superglobal
    echo "  \$_SERVER: " . (isset($_SERVER[$name]) ? $_SERVER[$name] : 'NOT FOUND') . "\n";
    
    echo "\n";
}

// Check WordPress-specific variables
echo "WordPress Variables:\n";
echo "==================\n";
check_env_var('MYSQL_DATABASE');
check_env_var('MYSQL_USER');
check_env_var('DOMAIN_NAME');
check_env_var('WP_TITLE');
check_env_var('WP_URL');

// Display all environment variables
echo "All Environment Variables:\n";
echo "=======================\n";
echo "getenv() variables:\n";
$env_vars = getenv();
if (is_array($env_vars)) {
    foreach ($env_vars as $key => $value) {
        echo "  $key: $value\n";
    }
} else {
    echo "  getenv() did not return an array\n";
}

echo "\n\$_ENV variables:\n";
foreach ($_ENV as $key => $value) {
    echo "  $key: $value\n";
}

echo "\n\$_SERVER variables:\n";
foreach ($_SERVER as $key => $value) {
    if (!is_array($value)) {
        echo "  $key: $value\n";
    }
}

// PHP information
echo "\nPHP Configuration:\n";
echo "=================\n";
echo "PHP Version: " . phpversion() . "\n";
echo "php.ini loaded: " . php_ini_loaded_file() . "\n";

// PHP-FPM information if available
if (function_exists('fpm_get_status')) {
    echo "\nPHP-FPM Status Available\n";
} else {
    echo "\nPHP-FPM Status Not Available\n";
}