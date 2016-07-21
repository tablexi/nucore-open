class ResultsFileNotifierPreview < ActionMailer::Preview

  def file_uploaded
    file = StoredFile.sample_result.last
    ResultsFileNotifierMailer.file_uploaded(file)
  end

end
