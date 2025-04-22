<?php
/**
 * WordPress Configuration File - Fixed version with proper environment handling
 */

// For debugging during setup
error_log('WordPress config initialization starting');

// More robust environment variable retrieval
function get_env_var($name, $default = '') {
    // Try multiple methods to get environment variables
    $value = getenv($name);
    
    // Check $_ENV superglobal as an alternative
    if (empty($value) && isset($_ENV[$name])) {
        $value = $_ENV[$name];
    }
    
    // Check $_SERVER as a last resort
    if (empty($value) && isset($_SERVER[$name])) {
        $value = $_SERVER[$name];
    }
    
    // Log environment variable attempt
    error_log("Getting env var $name: " . (empty($value) ? "NOT FOUND, using default: $default" : "FOUND: $value"));
    
    return empty($value) ? $default : $value;
}

// Try to get DB info from environment variables with fallbacks
$db_name = get_env_var('MYSQL_DATABASE', 'wordpress');
$db_user = get_env_var('MYSQL_USER', 'wp_user');
$db_password = '';

// Try to read DB password from secret file
if (file_exists('/run/secrets/db_password')) {
    $db_password = trim(file_get_contents('/run/secrets/db_password'));
    error_log('DB_PASSWORD read from secret file, length: ' . strlen($db_password));
} else {
    error_log('Secret file not found, using fallback password');
    $db_password = 'mydbpass'; // Fallback password
}

// Define DB constants
define('DB_NAME', $db_name);
define('DB_USER', $db_user);
define('DB_PASSWORD', $db_password);
define('DB_HOST', 'mariadb');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// Get domain from environment with fallback
$domain = get_env_var('DOMAIN_NAME', 'pmelis.42.fr');

// Authentication unique keys and salts - these should be unique but static values work for now
define('AUTH_KEY',         'QR*Hz#j|y:Ob}gp]+D{@vq=4eZ_;K+F-&y)|?ILQR|E1R=N,>x$+.gGl]xK6H0m|');
define('SECURE_AUTH_KEY',  'x@{+r=mG1eQJaH{p@+$0,HK-;6o-YlG%6|VaO31+V:DwxL #+K67r{+%7EV@&>-f');
define('LOGGED_IN_KEY',    '3l6a/$1F-WS*bZXW2|EI-j5<|9!+h3/tM+o7n5FI|{aIWl%Z4GeDJw9bD&fMsR=f');
define('NONCE_KEY',        'QiPF<G%3P?|FzS^*g0vbfYD8z-d3&C5fRR=m$yN?!_Z-U94E0T+2X{<k,g-hQxmc');
define('AUTH_SALT',        'j:uA+g-n+f.1IB*cxDf3OC-P?t|;M8A<e:X+/V(45]h%0d$t{J<jEXo`n0SU;*)K');
define('SECURE_AUTH_SALT', 'Zx45~tij-o<4<t)~E7,?I$U{V:A]+/7{Y]N|*t&^9-Yjl,b+RHFwPWnGS+tCQzA6');
define('LOGGED_IN_SALT',   '$TrAc}6R+{W:-l;fB>>iJE$H|hwj>5$Wx1IM.X*8Yx|j9Q/zK2-/fpC?rBBs+iGH');
define('NONCE_SALT',       '>Cfy>T!g9k=z+O4Rl$TDOX;+:AYO1jba|t|x|XSN1oq#0Jw&P(3_1Oi+HI@?!1SJ');

// WordPress database table prefix
$table_prefix = 'wp_';

// For debugging
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);

// If we're behind a proxy server and using HTTPS, we need to alert WordPress of that fact
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// Site URL settings
define('WP_SITEURL', 'https://' . $domain);
define('WP_HOME', 'https://' . $domain);

// Performance settings
define('WP_MEMORY_LIMIT', '256M');
define('AUTOMATIC_UPDATER_DISABLED', true);

// Log final database connection parameters (remove in production)
error_log('Final DB connection parameters:');
error_log('DB_NAME: ' . DB_NAME);
error_log('DB_USER: ' . DB_USER);
error_log('DB_HOST: ' . DB_HOST);
error_log('DB_PASSWORD length: ' . strlen(DB_PASSWORD));

// Absolute path to the WordPress directory
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

// Load WordPress settings
require_once ABSPATH . 'wp-settings.php';