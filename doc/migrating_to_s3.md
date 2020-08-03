# Migrating to S3

### Migrate locally stored file path

Ensure that everything is in `public/system` per the recent changes in the settings.

See [the CHANGELOG](../CHANGELOG.md) for instructions.

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
