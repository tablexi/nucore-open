# This is what makes the nucore extension system work.
# See doc/HOWTO_extensions for details on nucore extensions.
Dir["#{Rails.root}/lib/extensions/*.rb"].each do |file|
  require file
  file_name=File.basename(file, File.extname(file))
  next unless file_name.ends_with?('_extension')
  base_name=file_name[0...file_name.rindex('_')]
  base=base_name.camelize.constantize

  base.class_eval %Q<
    after_find :hook_extension if self.respond_to? :after_find

    def initialize(*args)
      super(*args)
      hook_extension
    end

    private

    def hook_extension
      extend #{file_name.camelize}
    end
  >
end