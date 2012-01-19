require File.expand_path('base', File.dirname(__FILE__))

Daemons::Base.new('auto_cancel').start do
  puts "Zzzzzz.."
  sleep 5
end


