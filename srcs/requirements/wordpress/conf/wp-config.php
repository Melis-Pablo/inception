<?php
/**
 * WordPress Configuration File
 */

// Database settings
define('DB_NAME', getenv('MYSQL_DATABASE'));
define('DB_USER', getenv('MYSQL_USER'));
define('DB_PASSWORD', trim(file_get_contents('/run/secrets/db_password')));
define('DB_HOST', 'mariadb');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// Authentication unique keys and salts
// These will be replaced by the init script with random values
define('AUTH_KEY',         'placeholder');
define('SECURE_AUTH_KEY',  'placeholder');
define('LOGGED_IN_KEY',    'placeholder');
define('NONCE_KEY',        'placeholder');
define('AUTH_SALT',        'placeholder');
define('SECURE_AUTH_SALT', 'placeholder');
define('LOGGED_IN_SALT',   'placeholder');
define('NONCE_SALT',       'placeholder');

// WordPress database table prefix
$table_prefix = 'wp_';

// Handle HTTPS properly
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// Site URL settings
define('WP_SITEURL', 'https://' . getenv('DOMAIN_NAME'));
define('WP_HOME', 'https://' . getenv('DOMAIN_NAME'));

// Absolute path to the WordPress directory
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

// Load WordPress settings
require_once ABSPATH . 'wp-settings.php';