class Reports::ExportRawFactory
  @@reports_export_raw_class = Settings.reports.export_raw.class_name.constantize

  def self.instance(*args)
    @@reports_export_raw_class.new(*args)
  end
end
