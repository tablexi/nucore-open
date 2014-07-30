module ReassignChartStringsHelper
  def available_account_select_tag(form, accounts)
    form.input :account_id,
      as: :select,
      collection: accounts,
      input_html: {
        class: 'account_selection',
        data: {
          placeholder: I18n.t('facilities.reassign_chart_strings.account_select.placeholder')
        }
      }
  end
end
