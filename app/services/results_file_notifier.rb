class ResultsFileNotifier

  attr_reader :file

  def initialize(file)
    @file = file
  end

  def notify
    if SettingsHelper.feature_on?(:my_files)
      ResultsFileNotifierMailer.file_uploaded(file).deliver_later
    end
  end

end
