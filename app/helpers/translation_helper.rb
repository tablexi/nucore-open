module TranslationHelper
  def t_manage_models(clazz)
    I18n.t('pages.manage', :model => clazz.model_name.human.pluralize)
  end
  def t_my(clazz)
    I18n.t('pages.my_tab', :model => clazz.model_name.human.pluralize)
  end
end