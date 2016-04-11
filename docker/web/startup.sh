#!/bin/sh

script/delayed_job start
bin/rake daemon:start[auto_cancel]
whenever --update-crontab --set 'environment=development'
bin/rails server --port 3000 --binding 0.0.0.0
