module ReportsHelper
  include DateHelper

  def to_hours(minutes)
    (minutes / 60).round(2)
  end

  def time_difference(end_at, start_at)
    return '' unless start_at && end_at
    minutes = (truncate_seconds(end_at) - truncate_seconds(start_at)) / 60
    minutes.to_s
  end

  def truncate_seconds(datetime)
    datetime.change(:sec => 0)
  end

  def to_percent(decimal)
    (decimal * 100).round(1)
  end


  def report_attributes(*records)
    combine_attributes(*records) do |ar|
      order_and_filter_attributes(ar).collect{|attr| ActiveSupport::Inflector.humanize(attr[0])}
    end
  end


  def report_attribute_values(*records)
    combine_attributes(*records) do |ar|
      order_and_filter_attributes(ar).collect{|attr| attr[1]}
    end
  end


  private

  def combine_attributes(*records)
    attrs=[]
    records.each {|ar| attrs += yield(ar) }
    attrs
  end


  def order_and_filter_attributes(ar)
    attrs=ar.attributes.to_a
    attrs.delete_if{|ray| ray[0] =~ /._id$|^id$|^updated_at$|^created_at$|._by$/}
    attrs.sort{|a1, a2| a1[0] <=> a2[0]}
  end

end