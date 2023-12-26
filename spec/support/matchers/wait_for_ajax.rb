# frozen_string_literal: true

puts "Loading spec/support/matchers/wait_for_ajax.rb"

module WaitForAjax

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script("jQuery.active").zero?
  end

end

RSpec.configure do |config|
  config.include WaitForAjax, type: :js
end
