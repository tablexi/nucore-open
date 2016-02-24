#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppHtmlBuilder

  attr_reader :html

  def initialize
    @html = Nokogiri::HTML::Document.new

    Nokogiri::HTML::Builder.with(html) do |doc|
      doc.html do
        doc.head do
          doc.link rel: "stylesheet", type: "text/css", href: File.expand_path("report.css", File.dirname(__FILE__))
        end
        doc.body do
          doc.article do
          end
        end
      end
    end
  end

  def report(detail, actuals, estimates)
    reservation = detail.reservation
    product = detail.product

    append_to_article do |doc|
      doc.section.comparison do
        doc.h2 "#{product.facility.name} | #{product.name} | #{detail}"
        doc.p "Reserved for #{(reservation.reserve_end_at - reservation.reserve_start_at) / 60} minutes"
        doc.p "Used for #{(reservation.actual_end_at - reservation.actual_start_at) / 60} minutes"
        doc.table(border: 1) do
          doc.tr do
            doc.th
            doc.th "Old"
            doc.th "New"
          end

          doc.tr do
            doc.td.label "Estimated Cost"
            doc.td detail.estimated_cost.to_f
            doc.td estimates[:cost].to_f
          end

          doc.tr do
            doc.td.label "Estimated Subsidy"
            doc.td detail.estimated_subsidy.to_f
            doc.td estimates[:subsidy].to_f
          end

          doc.tr do
            doc.td.label "Actual Cost"
            doc.td detail.actual_cost.to_f
            doc.td actuals[:cost].to_f
          end

          doc.tr do
            doc.td.label "Actual Subsidy"
            doc.td detail.actual_subsidy.to_f
            doc.td actuals[:subsidy].to_f
          end
        end
      end
    end
  end

  def summarize(reporter)
    append_to_article do |doc|
      doc.section.summary! do
        doc.h2 "Summary"
        doc.p "#{reporter.details.size} new, in process, or completed reservations processed"
        doc.p "#{reporter.changed} had different prices while #{reporter.details.size - reporter.changed} were the same"
      end
    end
  end

  def report_errors(reporter)
    append_to_article do |doc|
      doc.section.errors! do
        doc.details do
          doc.summary "Errors"
          reporter.errors.each { |err| doc.pre err }
        end
      end
    end
  end

  def render
    File.write "price_change_report.html", "<!DOCTYPE html>#{html.root}"
  end

  def append_to_article
    Nokogiri::HTML::Builder.with(html.at("article")) { |doc| yield doc }
  end

end
