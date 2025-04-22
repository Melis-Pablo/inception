<?php
/**
 * WordPress Configuration File
 */

// ** Database settings ** //
define( 'DB_NAME', getenv('MYSQL_DATABASE') );
define( 'DB_USER', getenv('MYSQL_USER') );
define( 'DB_PASSWORD', trim(file_get_contents('/run/secrets/db_password')) );
define( 'DB_HOST', 'mariadb' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

// Authentication unique keys and salts
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

// WordPress database table prefix
$table_prefix = 'wp_';

// Debug mode
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );

// If we're behind a proxy server and using HTTPS, we need to alert WordPress of that fact
if ( isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https' ) {
    $_SERVER['HTTPS'] = 'on';
}

// WordPress address (URL) settings
define( 'WP_SITEURL', 'https://' . getenv('DOMAIN_NAME') );
define( 'WP_HOME', 'https://' . getenv('DOMAIN_NAME') );

// Increase memory limit
define( 'WP_MEMORY_LIMIT', '256M' );

// Disable automatic updates
define( 'AUTOMATIC_UPDATER_DISABLED', true );

// Absolute path to the WordPress directory
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

// Sets up WordPress vars and included files
require_once ABSPATH . 'wp-settings.php';