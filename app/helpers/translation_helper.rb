# frozen_string_literal: true

module TranslationHelper

  def t_manage_models(clazz)
    text("pages.manage", model: clazz.model_name.human(count: :many))
  end

  def t_create_model(clazz)
    text("pages.create", model: clazz.model_name.human)
  end

  def t_create_models(clazz)
    text("pages.create", model: clazz.model_name.human(count: :many))
  end

  def t_my(clazz)
    text("pages.my_tab", model: clazz.model_name.human(count: :many))
  end

  def t_model_error(clazz, error, *options)
    text("activerecord.errors.models.#{clazz.model_name.to_s.underscore}.#{error}", *options)
  end

  def t_boolean(value)
    text(value.to_s, scope: "boolean")
  end

  # Strips HTML line breaks. Useful when using text-helper's `text` method so you
  # can have a single line break.
  def strip_br(string)
    string.gsub(/<br\/?>/, "")
  end

end
