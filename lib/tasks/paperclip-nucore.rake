# frozen_string_literal: true

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

    journals = Journal.where("file_file_name IS NOT NULL")
    stored_files = StoredFile.where("file_file_name IS NOT NULL")

    file_index = 0
    file_count = journals.count + stored_files.count

    journals.each do |journal|
      file_index += 1
      puts "File #{file_index} of #{file_count}"
      push_to_s3(journal, journal.file_file_name)
    end

    stored_files.each do |stored_file|
      file_index += 1
      puts "File #{file_index} of #{file_count}"
      push_to_s3(stored_file, stored_file.file_file_name.tr('#', "-"))
    end
  end

  namespace :mime do
    desc "Derive MIME types from file extensions"
    task update_from_file_extensions: :environment do
      (Journal.where("file_file_name IS NOT NULL") + StoredFile.where("file_file_name IS NOT NULL")).each do |file|

        print "#{file.class} #{file.id}: #{file.file_file_name} "

        extension = File.extname(file.file_file_name).sub(/^\./, "")
        if extension.blank?
          puts "WARNING: the file extension is blank!"
          next
        end

        mime_type = Mime::Type.lookup_by_extension(extension)
        if mime_type.blank?
          puts "WARNING: cannot look up extension #{extension}"
          next
        end

        if file.file_content_type == mime_type.to_s
          puts "is already set correctly to #{mime_type}"
          next
        end

        if file.update_attribute(:file_content_type, mime_type.to_s)
          puts "content type set to #{mime_type}"
        else
          puts "WARNING: COULD NOT set content type to #{mime_type}"
        end
      end
    end
  end
end
