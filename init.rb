require 'vendor/validation_reflection'

ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| html_tag }

ActionView::Base.send :include, AirBlade::AirBudd::FormHelper
