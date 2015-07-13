namespace :paperclip do
  def paperclip_allow_task?
    if Settings.paperclip.storage == "fog"
      true
    else
      puts "Cannot move files to S3 unless paperclip storage is set to 'fog'."
      puts "See the section on configuring file storage in the README."
      false
    end
  rescue NoMethodError
    puts "It doesn't look like paperclip is configured."
    puts "See the section on configuring file storage in the README."
    false
  end

  def push_to_s3(item, filename)
    id_partition = ("%09d" % item.id).scan(/\d{3}/).join("/")
    local_filepath = "#{Rails.root}/public/files/#{id_partition}/original/#{filename}"

    print "Processing #{local_filepath}"

    File.open(local_filepath) do |filehandle|
      item.file.assign(filehandle)
      if item.file.save
        puts "; stored to #{item.file.url}"
      else
        puts "; S3 store failed!"
      end
    end
  rescue Errno::ENOENT => e
    puts ": Skipping! File does not exist."
  end

  desc "Move files from local to S3"
  task move_to_s3: :environment do
    next unless paperclip_allow_task?

    Journal.where("file_file_name IS NOT NULL").each do |journal|
      push_to_s3(journal, journal.file_file_name)
    end

    StoredFile.where("file_file_name IS NOT NULL").each do |stored_file|
      push_to_s3(stored_file, stored_file.file_file_name.gsub(/#/, "-"))
    end
  end
end
