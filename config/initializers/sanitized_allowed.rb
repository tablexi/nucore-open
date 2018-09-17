# frozen_string_literal: true

ActionView::Base.sanitized_allowed_attributes << "style"
ActionView::Base.sanitized_allowed_tags += %w(table thead tbody th tr td)
