npm install fine-uploader

mkdir -p vendor/assets/javascripts/fine-uploader
cp node_modules/fine-uploader/fine-uploader/*.js vendor/assets/javascripts/fine-uploader
cp node_modules/fine-uploader/*.fine-uploader/*.js vendor/assets/javascripts/fine-uploader

mkdir -p vendor/assets/stylesheets/fine-uploader
cp node_modules/fine-uploader/fine-uploader/*.css vendor/assets/stylesheets/fine-uploader

mkdir -p vendor/assets/images/fine-uploader
cp node_modules/fine-uploader/fine-uploader/*.gif vendor/assets/images/fine-uploader

mkdir -p vendor/assets/images/fine-uploader/placeholders
cp node_modules/fine-uploader/fine-uploader/placeholders/*.png vendor/assets/images/fine-uploader/placeholders

mkdir -p vendor/assets/templates/fine-uploader
cp node_modules/fine-uploader/fine-uploader/templates/*.html vendor/assets/templates
