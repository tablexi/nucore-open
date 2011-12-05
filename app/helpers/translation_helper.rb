module TranslationHelper
  def t_manage_models(clazz)
    I18n.t('pages.manage', :model => clazz.human_name.pluralize)
  end
  def t_my(clazz)
    I18n.t('pages.my_tab', :model => clazz.human_name.pluralize)
  end
end