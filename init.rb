ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| html_tag }

ActionView::Base.send :include, AirBlade::AirBudd::FormHelper

# If you want to use HAML, there are two steps.
#
# 1.  Uncomment the line below:
#
#     AirBlade::AirBudd::FormBuilder.send :include, Haml::Helpers
#
# 2.  In your app's config/environment.rb, find the line that
#     specifies the order in which your plugins load and make sure
#     that HAML loads before this plugin.  For example:
#
#     config.plugins = [ :haml, :air_budd_form_builder, :all ]
