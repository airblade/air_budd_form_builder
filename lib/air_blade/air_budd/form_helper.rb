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
    end
  end
end
