module.exports = {
  apps: [
    {
      name: 'dtexxchange-backend',
      script: 'dist/src/main.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      error_file: './logs/pm2-error.log',
      out_file: './logs/pm2-out.log',
      env: {
        NODE_ENV: 'production',
      },
    },
  ],
};
