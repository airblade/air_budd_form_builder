module AirBlade
  module AirBudd
    module FormHelper
      # Similar to +form_for+ but uses our form builder.
      def airbudd_form_for(name, *args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options = options.merge :builder => AirBlade::AirBudd::FormBuilder
        form_for(name, *(args << options), &block)
      end

      # Similar to +fields_for+ but uses our form builder.
      def airbudd_fields_for(name, *args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options = options.merge :builder => AirBlade::AirBudd::FormBuilder
        fields_for(name, *(args << options), &block)
      end

      # Displays a link visually consistent with AirBudd form links.
      # TODO: complete this.  See README.
      def link_to_form(purpose, options = {}, html_options = nil)
        icon = case purpose
               when :edit then 'pencil'
               end
        legend = ( icon.nil? ?
                   '' :
                   "<img src='/images/icons/#{icon}.png' alt=''></img> " ) +
                 (options[:label] || purpose.to_s.capitalize)
        '<div class="buttons">' +
        link_to(legend, options, html_options) +
        '</div>'
      end
    end
  end
end
