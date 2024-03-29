# Changelog

Because we use squash and merge, you should be able to see the changes by looking
at the [commit log](https://github.com/tablexi/nucore-open/commits/master). However, we have begun keeping track of breaking changes
or optional rake tasks.

### Addition of `PriceGroupDiscount` ([#3397](https://github.com/tablexi/nucore-open/pull/3397), [#3594](https://github.com/tablexi/nucore-open/pull/3594))

Rather than one discount being set on a schedule rule, each global price group has its own discount (`PriceGroupDiscount`) for each schedule rule.

When transitioning a school to use `PriceGroupDiscount`s, the `schedule_rule:add_price_group_discounts` rake task should be run, which adds `PriceGroupDiscount`s for every global price group to every schedule rule.

When adding a new global price group, the `price_group:add_global_price_group` rake task should be run. This creates the global price group and sets up `PriceGroupDiscount`s for it for every schedule rule.

### Addition of `facility_tile_list: true` feature flag ([#3193](https://github.com/tablexi/nucore-open/pull/3193))

Schools that have set the feature flag `facility_tile_list: false` are not affected by this change.

Schools that have set the feature flag `facility_tile_list: true` have the home page's facility list in a tiled grid that can include images of each facility.

This change is a new implementation of this feature flag and may require changes to existing implementations.

In this implementation, facilities get their attached image via the `DownloadableFiles::Image` module. This module uses either Paperclip or ActiveStorage, depending on the `active_storage` feature flag. The attachment is called `file` and, if Paperclip is being used, the following migration is needed

```ruby
class AddAttachmentToFacility < ActiveRecord::Migration[6.1]
  def change
    add_attachment :facilities, :file
  end
end
```

In addition to this, interactions with the image are done using the `DownloadableFile` interface, rather than directly using Paperclip or ActiveStorage's interface.


### Change in behavior of feature flag `expense_accounts: false` ([#3153](https://github.com/tablexi/nucore-open/pull/3153))

Schools that have set the feature flag `expense_accounts: true` are not affected by this change.
Schools that have set the feature flag `expense_accounts: false` typically include the `revenue_account` as part of the chart string account number.
This changes expands the scope of the feature flag, so that when it is set to `false`:
- The `revenue_account` value is not displayed in parentheses as part of the account number
- The input for `revenue_account` is hidden, but the value is still set to `Settings.accounts.revenue_account_default`
- You can determine what value to include in journal exports by over-riding the `FacilityAccount#revenue_account_for_journal` method.  The default is `revenue_account`.

### Use `.bashrc` to determine which servers should run recurring tasks ([#2994](https://github.com/tablexi/nucore-open/pull/2994))

The `recurring_tasks` process should only run on one server per environment.   Set `RECURRING=true` in the environment (`.bashrc` for example) to configure which servers should run these tasks.  Attempting to set this via `capistrano` only works on deploy.

### Rename `auto_cancel` daemon to `recurring_tasks` and consolidate recurring tasks there ([#2957](https://github.com/tablexi/nucore-open/pull/2957))

The `recurring_tasks` process should only run on one server per environment.  This is managed via `eye` now.  If you user another deployment process and have multiple servers running in production, you will need to ensure this daemon only runs on one server.  Setting `run_auto_cancel: false` in `secrets.yml` will no longer have an impact.  The list of recurring jobs is listed in `RecurringTaskConfig`.  You can add or remove items from the list from your school-specific engine like so:
```ruby
RecurringTaskConfig.recurring_tasks << [SecureRooms::AutoOrphanOccupancy, :perform, 5]
```

### Configure `auto_cancel` process via `secrets.yml` ([#2544](https://github.com/tablexi/nucore-open/pull/2544))

The `auto_cancel` process should only run on one server per environment.  If you have multiple servers running in production, set`run_auto_cancel: false` in `secrets.yml` on all but one production server.

### Rename username attribute key in `ldap.yml.template` ([#2440](https://github.com/tablexi/nucore-open/pull/2440))

If you are using the [LDAP Authenitcation engine](vendor/engines/ldap_authentication/README.md) and have set a value for the `attribute` key in `ldap.yml`, you will need to rename the key to `username_attribute`.

```yaml
# Old setting
attribute: uid

# New setting
username_attribute: uid
```

### Uploaded file storage path change ([#2365](https://github.com/tablexi/nucore-open/pull/2365))

We want to move everything into `public/system`, which is the more modern standard.

In addition, with the previous default in settings.yml, files were not stored according to their
class, so objects of different types with the same IDs could share the same folder, so
we also want to add the class name to the path.

```yaml
# Old setting
paperclip:
  storage: filesystem
  url: ":rails_relative_url_root/:attachment/:id_partition/:style/:safe_filename"
  path: ":rails_root/public/:attachment/:id_partition/:style/:safe_filename"

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


### Welcome email refactoring/cleanup ([#2362](https://github.com/tablexi/nucore-open/pull/2362))

The locales for the new user (welcome) email have been simplified. If you have customized
this email, you will need to make some changes.

`views.notifier.new_user` no longer uses any keys with the `_html` and `_text` suffixes.
We recommend deleting one of the entries and removing the suffix from the other for each
of `intro`, `only_username`, `username_and_password`, and `outro`. The content is presented
as is for the plain-text version and parsed via Markdown for the HTML version.

For development, we've improved the previews so you can see both a netid user email
as well as an external user email. http://localhost:3000/rails/mailers/notifier

### Rename BaseMailer to ApplicationMailer ([#2362](https://github.com/tablexi/nucore-open/pull/2362))

If you have custom mailers in any of your engines, you might need to rename `< BaseMailer` to
`< ApplicationMailer`.

### Fix price group membership logs ([#2360](https://github.com/tablexi/nucore-open/pull/2360))

In order to address an issue with add/removing subclasses of PriceGroupMember, we
need to clean up old data:

```
rake cleanup:log_events:metadata
```

### [Optional] Remove Cancer Center Price Group ([#2347](https://github.com/tablexi/nucore-open/pull/2347))

Many schools do not have a cancer center, so the price group does not make sense to
include. For new implementations of NUcore, you can simply remove `price_group.name.cancer_center` from `settings.yml` when you run the seeds.

```
rake cleanup:price_groups:cancer_center
```

### [Recommended] Remove abandoned carts ([#2292](https://github.com/tablexi/nucore-open/pull/2292))

After releasing this PR, many fewer abandoned instrument-only carts should be created (see
the PR for details on why). This rake task will clean up the existing abandoned carts,
which could improve site performance for some users.

```
bundle exec rake cleanup:carts:destroy_abandoned
```
