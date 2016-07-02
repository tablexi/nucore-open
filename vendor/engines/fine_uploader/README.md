# FineUploader for Rails Asset Pipeline

[Fine Uploader](http://fineuploader.com/) is a JavaScript plugin for handling multiple file uploads featuring drag and drop functionality. See their website for more details.

As of [May 19, 2016](https://blog.fineuploader.com/2016/05/19/fine-uploader-5-9-free-at-last/), Fine Uploader is licensed under the MIT license.

This gem is currently being tested within [NUcore](github.com/tablexi/nucore-open), and if we're happy with it, will be extracted into its own gem.

## Installation

_TODO: Update once this is its own gem_

```ruby
gem "fine-uploader", path: "vendor/engines/fine_uploader"
```

### Using the javascript

This gem includes both the normal version as well as the jQuery version. It also includes the S3 and Azure versions.

Include the library within your application.js file using one of the following lines:

```
//= require fine-uploader/fine-uploader
//= require fine-uploader/jquery.fine-uploader
//= require fine-uploader/s3.fine-uploader
//= require fine-uploader/s3.jquery.fine-uploader
```

or if you need it just a subset of pages:

```
<%= javascript_include_tag "fine-uploader/fine-uploader" %>
```

### Include the stylesheets

In your application.css

```
*= require fine-uploader/fine-uploader-new
```

or application.scss

```
@import "fine-uploader/fine-uploader-new"
```

## Include in a page

Using the jQuery version (see the [docs](http://docs.fineuploader.com/quickstart/01-getting-started.html) for non-jquery javascript):

```erb
<div id="fine-uploader" data-authenticity-token="<%= form_authenticity_token" %>></div>
<script>
  $("#fine-uploader").fineUploader({
    request: {
      endpoint: <%= file_upload_path %>,
      params: {
        authenticity_token: $("#fine-uploader").data("authenticity-token")
      }
    }
  })
</script>
```

You also need to include the `<script type="text/template" id="qq-template">` section from one of the template files in [vendor/assets/templates](vendor/assets/templates) in your HTML.

## Building

Building a new version requires `npm`.

```
./build.sh
```
