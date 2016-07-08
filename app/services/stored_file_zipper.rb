class StoredFileZipper
  attr_reader :files

  def initialize(files)
    @files = files
  end

  def read
    return @read if @read
    zip_io = build_zip
    zip_io.rewind
    @read = zip_io.read
  end

  private

  def build_zip
    Zip::OutputStream.write_buffer do |stream|
      files.each do |file|
        stream.put_next_entry(file.name)
        stream << file.read
      end
    end
  end
end
