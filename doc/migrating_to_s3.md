# Migrating to S3

### Migrate locally stored file path

We want to move everything into `public/system`.

With the previous default in settings.yml, files were not stored according to their
class, so objects of different types with the same IDs could share the same folder, so
we also want to add the class name to the path.

```yaml
# Old setting
paperclip:
  storage: filesystem
  url: ":rails_relative_url_root/:attachment/:id_partition/:style/:safe_filename"
  path: ":rails_root/public/:class/:attachment/:id_partition/:style/:safe_filename"

# New setting
paperclip:
  storage: filesystem
  url: ":rails_relative_url_root/system/:class/:attachment/:id_partition/:style/:safe_filename"
  path: ":rails_root/public/system/:class/:attachment/:id_partition/:style/:safe_filename"
```

_If your old setting for `path` was something different, you'll need to change it
in `lib/tasks/paperclip-nucore.rake`_

* Take a backup of `public/files`

* Move the files to the new location

  ```
  bundle exec rake paperclip:migrate_path
  ```

* Restart the server so it points at the new location

### Sync the folder to S3

This does an rsync-style sync, so you can run it once initially and then it'll only
copy over new files the next time you run it. See [the AWS docs](https://docs.aws.amazon.com/cli/latest/reference/s3/sync.html) for more information.

```
aws s3 sync public/system s3://BUCKET_NAME --acl private
# Optional argument: --dryrun
```

### Update the application settings

Add your AWS access keys either to the ENV or to `secrets.yml` (see <config/secrets.yml.template>) on the server.

Update `config/settings/ENVIRONMENT.yml` to use `fog` as the provider for Paperclip and
configure the bucket (and region if necessary).

```yaml
paperclip:
  storage: fog
  fog_credentials:
    provider: AWS
    aws_access_key_id: <%= ENV.fetch("AWS_ACCESS_KEY", Rails.application.secrets.dig(:paperclip, :aws_access_key_id)) %>
    aws_secret_access_key: <%= ENV.fetch("AWS_SECRET_ACCESS_KEY", Rails.application.secrets.dig(:paperclip, :aws_secret_access_key)) %>
  fog_directory: "nucore-production"
  fog_public: false
  path: ":class/:attachment/:id_partition/:style/:safe_filename"
```

Deploy the application.

Run the sync one last time.
