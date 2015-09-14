class MessageSummarizer::MessageSummary
  attr_reader :controller

  def initialize(controller)
    @controller = controller
  end

  def any?
    count > 0
  end

  def count
    @count ||= allowed? ? get_count : 0
  end

  def link
    controller.view_context.link_to(label, path)
  end

  private

  def ability
    controller.current_ability
  end

  def allowed?
    raise NotImplementedError.new("Subclass must implement")
  end

  def facility
    controller.current_facility
  end

  def get_count
    raise NotImplementedError.new("Subclass must implement")
  end

  def i18n_key
    raise NotImplementedError.new("Subclass must implement")
  end

  def label
    "#{I18n.t(i18n_key)} (#{count})"
  end

  def path
    raise NotImplementedError.new("Subclass must implement")
  end
end
