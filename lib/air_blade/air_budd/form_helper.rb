module AirBlade
  module AirBudd
    module FormHelper

      # Define form helpers that use our form builder.
      [ :form_for, :fields_for, :remote_form_for ].each do |method|
        code = <<-END
          def airbudd_#{method}(name, *args, &block)
            options = args.last.is_a?(Hash) ? args.pop : {}
            options = options.merge :builder => AirBlade::AirBudd::FormBuilder
            #{method}(name, *(args << options), &block)
          end
        END
        module_eval code, __FILE__, __LINE__
      end


      # Displays a link visually consistent with AirBudd form links.
      # TODO: complete this.  See README.
      # TODO: DRY with FormBuilder#button implementation.
      def link_to_form(purpose, options = {}, html_options = nil)
        icon = options.delete(:icon) if options.respond_to?(:has_key?)
        icon ||= case purpose
                 when :new    then 'add'
                 when :edit   then 'pencil'
                 when :delete then 'cross'  # TODO: delete should be a button, not a link
                 when :cancel then 'arrow_undo'
                 end
        if options.kind_of? String
          url = options
        else
          url = options.delete :url
          label = options.delete :label
        end
        label ||= purpose.to_s.capitalize
        legend = ( icon.nil? ?
                   '' :
                   "<img src='/images/icons/#{icon}.png' alt=''></img> " ) + label
        
        '<div class="buttons">' +
        link_to(legend, (url || options), html_options) +
        '</div>'
      end
    end
  end
end
