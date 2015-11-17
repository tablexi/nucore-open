module ViewHookHelper

  # Look up the current path and render the view hooks for a specific placement
  def view_hook(placement, args = {})
    # Take from translation helper shortcut (e.g. `t(".locale")`), this takes the
    # current view path, and converts slashes to dots, and the underscored partial as well
    # "facilities/manage" => "facilities.manage"
    # "facilities/_facility_fields" => "facilities/facility_fields"
    path = @virtual_path.gsub(%r{/_?}, ".")
    ViewHook.render_placement(path,  placement, self, args)
  end

end
