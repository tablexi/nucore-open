module TranslationHelper
  def t_manage_models(clazz)
    I18n.t('pages.manage', :model => clazz.model_name.human.pluralize)
  end
  def t_create_model(clazz)
    I18n.t("pages.create", :model => clazz.model_name.human)
  end
  def t_create_models(clazz)
    I18n.t("pages.create", :model => clazz.model_name.human.pluralize)
  end
  def t_my(clazz)
    I18n.t('pages.my_tab', :model => clazz.model_name.human.pluralize)
  end
  def t_model_error(clazz, error, *options)
    I18n.t("activerecord.errors.models.#{clazz.model_name.underscore}.#{error}", *options)
  end
end