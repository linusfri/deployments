{
  "clear_env" = "no";
  "pm" = "dynamic";
  "pm.max_children" = 10;
  "pm.start_servers" = 10;
  "pm.min_spare_servers" = 1;
  "pm.max_spare_servers" = 10;
  "request_terminate_timeout" = 360;
  "php_flag[display_errors]" = true;
  "php_admin_value[error_log]" = "/var/log/phpfpm-error.log";
  "php_admin_flag[log_errors]" = true;
  "php_value[memory_limit]" = "512M";
  "catch_workers_output" = true;
  "php_value[upload_max_filesize]" = "64M";
  "php_value[post_max_size]" = "64M";
}