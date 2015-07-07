namespace :paperclip do
  desc "Move files from local to S3"
  task move_to_s3: :environment do
    StoredFile.all.each do |stored_file|
      id_partition = ("%09d" % stored_file.id).scan(/\d{3}/).join("/")
      filename = stored_file.file_file_name.gsub(/#/, "-")
      local_filepath = "#{Rails.root}/public/files/#{id_partition}/original/#{filename}"

      print "Processing #{local_filepath}"

      begin
        File.open(local_filepath) do |filehandle|
          stored_file.file.assign(filehandle)
          if stored_file.file.save
            puts "; stored to #{stored_file.file.url}"
          else
            puts "; S3 store failed!"
          end
        end
      rescue Errno::ENOENT => e
        puts ": Skipping! File does not exist."
      end
    end
  end
end
