# frozen_string_literal: true

# For use with DateTimeInput, when you just need a datepicker (no time inputs)
#
# Usage:
# In your model:
# class JournalClosingReminder < ApplicationRecord
#   include DateTimeInput::Model
#   date_time_inputable :starts_at
# end
#
# ... and then in the view:
#   = f.input :starts_at, as: :date_dropdown
class DateDropdownInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    value = object.public_send("#{attribute_name}_date_time_data")
    @builder.simple_fields_for attribute_name, value do |f|
      f.input :date, include_blank: value.present?, label: false, input_html: { class: "datepicker"  }
    end
  end
end
