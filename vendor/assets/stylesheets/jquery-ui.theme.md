# Using a custom jquery-ui theme

As of jquery-ui 1.12/jquery-ui-rails 6, the default theme changed. The jquery-ui-rails
gem only includes the default (now "Base") theme. The old theme ("Smoothness")
looks better within the context of NUcore, so we keep a copy of the css in
vendor/engines.

* Download the Smoothness theme from https://jqueryui.com/themeroller

* Copy the `jquery-ui.css` file into vendor/assets/stylesheets

* Replace the hard-coded image paths with Rails asset paths and convert the file
to ERB:

```
cat vendor/assets/stylesheets/jquery-ui.css | perl -pe 's/url\("images\/([\w.-]+)"\)/url(<%= image_path("jquery-ui-smoothness\/\1") %>)/g' > vendor/assets/stylesheets/jquery-ui-smoothness.css.erb
```

* Delete the jquery-ui.css
