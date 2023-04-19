module ErrorsHelper

  def print_error_messages(errors, separator = "\n")
    errors.to_hash.map { |attr, messages| "#{attr} #{messages.join(', ')}" }.join(separator)
  end

end
