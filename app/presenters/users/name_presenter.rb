module Users

  class NamePresenter < SimpleDelegator

    def initialize(user, suspended_label: true, username_label: false)
      super(user)
      @suspended_label = suspended_label
      @username_label = username_label
    end

    def full_name
      render [first_name, last_name]
    end

    def last_first_name
      render [last_name, first_name].join(", ")
    end

    def render(name)
      parts = Array(name)
      parts << "(#{username})" if username_label?
      parts << "(#{user.class.human_attribute_name(:suspended)})" if suspended_label? && suspended?
      parts.join(" ")
    end

    def user
      __getobj__
    end

    private

    def username_label?
      @username_label
    end

    def suspended_label?
      @suspended_label
    end

    def append_suspended_string(string)
      if suspended?
        "#{string} (#{self.class.human_attribute_name(:suspended)})"
      else
        string
      end
    end
  end

end
