module ViewHook

  def self.add_hook(view, placement, partial)
    _view_hooks[view][placement] += [partial]
  end

  # Best used throught `view_hook` helper method
  def self.render_placement(view, placement, context, args = {})
    _view_hooks[view][placement].each_with_object("".html_safe) do |partial, buffer|
      buffer.safe_concat context.render(partial, args)
    end
  end

  private

  def self._view_hooks
    @@view_hooks ||= Hash.new { |h, k| h[k] = Hash.new([]) }
  end

end
