# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
Mime::Type.register "application/vnd.ms-excel", :xls
Mime::Type.register "text/calendar", :ics unless Mime::Type.lookup_by_extension(:ics)
