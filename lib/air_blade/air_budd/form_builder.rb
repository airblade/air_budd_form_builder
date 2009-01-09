module AirBlade
  module AirBudd

    class FormBuilder < ActionView::Helpers::FormBuilder
      include Haml::Helpers if defined? Haml       # for compatibility
      include ActionView::Helpers::TextHelper      # so we can use concat
      include ActionView::Helpers::CaptureHelper   # so we can use capture
      include ActionView::Helpers::TagHelper       # so we can use concat

      # App-wide form configuration.
      # E.g. in config/initializers/form_builder.rb:
      #
      #   AirBlade::AirBudd::FormBuilder.default_options[:required_signifier] = '*'
      #
      @@default_options = {
        :required_signifier => '(required)',
        :label_suffix => ':',
        :capitalize_errors => true,
      }
      cattr_accessor :default_options

      # Per-form configuration (overrides app-wide form configuration).
      # E.g. in a form itself:
      #
      #   - airbudd_form_for @member do |f|
      #     - f.required_signifier = '*'
      #     = f.text_field :name
      #     ...etc...
      #
      attr_writer *default_options.keys
      default_options.keys.each do |field|
        src = <<-END_SRC
          def #{field}
            @#{field} || default_options[:#{field}]
          end
        END_SRC
        class_eval src, __FILE__, __LINE__
      end

      @@field_keys = [:hint, :required, :label, :addendum, :suffix]

      alias_method :vanilla_hidden_field, :hidden_field

      # Creates a glorified form field helper.  It takes a form helper's usual
      # arguments with an optional options hash:
      #
      # <%= form.text_field 'title',
      #                     :required => true,
      #                     :label    => "Article's Title",
      #                     :hint     => "Try not to use the letter 'e'." %>
      #
      # The code above generates the following HTML.  The :required entry in the hash
      # triggers the <em/> element and the :label overwrites the default field label,
      # 'title' in this case, with its value.  The stanza is wrapped in a <p/> element.
      #
      # <p class="text">
      #   <label for="article_title">Article's Title:
      #     <em class="required">(required)</em>
      #   </label>
      #   <input id="article_title" name="article[title]" type="text" value=""/>
      #   <span class="hint">Try not to use the letter 'e'.</span>
      # </p>
      #
      # If the field's value is invalid, the <p/> is marked so and a <span/> is added
      # with the (in)validation message:
      #
      # <p class="error text">
      #   <label for="article_title">Article's Title:
      #     <em class="required">(required)</em>
      #     <span class="feedback">can't be blank</span>
      #   </label>
      #   <input id="article_title" name="article[title]" type="text" value=""/>
      #   <span class="hint">Try not to use the letter 'e'.</span>
      # </p>
      #
      # You can also pass an :addendum option.  This generates a <span/> between the
      # <input/> and the hint.  Typically you would use this to show a small icon
      # for deleting the field.
      def self.create_field_helper(field_helper)
        src = <<-END
          def #{field_helper}(method, options = {}, html_options = {})
            @template.content_tag('p',
                                  label_element(method, options, html_options) +
                                    super(method, options.except(*@@field_keys)) +
                                    addendum_element(options) +
                                    hint_element(options),
                                  attributes_for(method, '#{field_helper}')
            )
          end
        END
        class_eval src, __FILE__, __LINE__
      end

      def self.create_short_field_helper(field_helper)
        src = <<-END
          def #{field_helper}(method, options = {}, html_options = {})
            @template.content_tag('p',
                                  super(method, options.except(*@@field_keys)) +
                                    label_element(method, options, html_options) +
                                    hint_element(options),
                                  attributes_for(method, '#{field_helper}')
            )
          end
        END
        class_eval src, __FILE__, __LINE__
      end

      # Creates a hidden input field and a simple <span/> using the same
      # pattern as other form fields.
      def read_only_text_field(method_for_text_field, method_for_hidden_field = nil, options = {}, html_options = {})
        method_for_hidden_field ||= method_for_text_field
        @template.content_tag('p',
                              label_element(method_for_text_field, options, html_options) +
                                vanilla_hidden_field(method_for_hidden_field, options) +
                                @template.content_tag('span', object.send(method_for_text_field)) +
                                addendum_element(options) +
                                hint_element(options),
                              attributes_for(method_for_text_field, 'text_field')
        )
      end

      # TODO: DRY this with self.create_field_helper above.
      def self.create_collection_field_helper(field_helper)
        src = <<-END
          def #{field_helper}(method, choices, options = {}, html_options = {})
            @template.content_tag('p',
                                  label_element(method, options, html_options) +
                                    super(method, choices, options.except(*@@field_keys)) +
                                    addendum_element(options) +
                                    hint_element(options),
                                  attributes_for(method, '#{field_helper}')
            )
          end
        END
        class_eval src, __FILE__, __LINE__
      end

      def attributes_for(method, field_helper)
        # FIXME: there must be a neater way than below.  This is Ruby, after all.
        ary = []
        ary << 'error' if errors_for?(method)
        ary << input_type_for(field_helper) unless input_type_for(field_helper).blank?
        attrs = {}
        attrs[:class] = ary.reject{ |x| x.blank? }.join(' ') unless ary.empty?
        attrs
      end

      def input_type_for(field_helper)
        case field_helper
        when 'text_field';     'text'
        when 'text_area';      'text'
        when 'password_field'; 'password'
        when 'file_field';     'file'
        when 'hidden_field';   'hidden'
        when 'check_box';      'checkbox'
        when 'radio_button';   'radio'
        when 'select';         'select'
        when 'date_select';    'select'
        when 'time_select';    'select'
        when 'country_select'; 'select'
        else ''
        end
      end


      # Beefs up the appropriate field helpers.
      %w( text_field text_area password_field file_field
          date_select time_select country_select ).each do |name|
        create_field_helper name
      end

      # Beefs up the appropriate field helpers.
      %w( check_box radio_button ).each do |name|
        create_short_field_helper name
      end

      # Beefs up the appropriate field helpers.
      %w( select ).each do |name|
        create_collection_field_helper name
      end


      # Within the form's block you can get good buttons with:
      #
      #   <% f.buttons do |b| %>
      #     <%= b.save %>
      #     <%= b.cancel %>
      #   <% end %>
      #
      # You can have save, cancel, edit and delete buttons.
      # Each one takes an optional label.  For example:
      #
      #     <%= b.save :label => 'Update' %>
      #
      # See the documentation for the +button+ method for the
      # options you can use.
      #
      # You could call the button method directly, e.g. <%= f.button %>,
      # but then your button would not be wrapped with a div of class
      # 'buttons'.  The div is needed for the CSS.
      def buttons(&block)
        concat '<div class="buttons">', block.binding
        yield self
        concat '</div>', block.binding
      end

      # Buttons and links for REST actions.  Actions that change
      # state, i.e. save and delete, have buttons.  Other actions
      # have links.
      #
      # For visual feedback with colours and icons, save is seen
      # as a positive action; delete is negative.
      #
      # type = :new|:save|:cancel|:edit|:delete
      # TODO :all ?
      #
      # Options you can use are:
      #   :label - The label for the button or text for the link.
      #            Optional; defaults to capitalised purpose.
      #   :icon  - Whether or not to show an icon to the left of the label.
      #            Optional; icon will be shown unless :icon set to false.
      #   :url   - The URL to link to (only used in links).
      #            Optional; defaults to ''.
      def button(purpose = :save, options = {}, html_options = {})
        # TODO: DRY the :a and :button.
        element, icon, nature = case purpose
                                when :new    then [:a,      'add',        'positive']
                                when :save   then [:button, 'tick',       'positive']
                                when :cancel then [:a,      'arrow_undo', nil       ]
                                when :edit   then [:a,      'pencil',     nil       ]
                                when :delete then [:button, 'cross',      'negative']
                                end
        legend = ( (options[:icon] == false || options[:icon] == 'false') ?
                   '' :
                   "<img src='/images/icons/#{icon}.png' alt=''/> " ) +
                 (options[:label] || purpose.to_s.capitalize)

        html_options.merge!(:class => nature)
        if element == :button
          html_options.merge!(:type => 'submit')
        else
          html_options.merge!(:href => (options[:url] || ''))
        end

        # TODO: separate button and link construction and use
        # link_to to gain its functionality, e.g. :back?
        @template.content_tag(element.to_s,
                              legend,
                              html_options)
      end

      def method_missing(*args, &block)
        # Button method
        if args.first.to_s =~ /^(new|save|cancel|edit|delete)$/
          button args.shift, *args, &block
        else
          super
        end
      end

      private

      # Writes out a <label/> element for the given field.
      # Options:
      #  - :required: text to indicate that field is required.  Optional: if not given,
      #  field is not required.  If set to true instead of a string, default indicator
      #  text is '(required)'.
      #  - :label: text wrapped by the <label/>.  Optional (default is field's name).
      #  - :suffix: appended to the label.  Optional (default is ':').
      #  - :capitalize: false if any error message should not be capitalised,
      #    true otherwise.  Optional (default is true).
      def label_element(field, options = {}, html_options = {})
        return '' if options.has_key?(:label) && options[:label].nil?
        text = options.delete(:label) || (@object.nil? ? field.to_s.humanize : @object.class.human_attribute_name(field.to_s))
        suffix = options.delete(:suffix) || label_suffix
        value = text + suffix
        if (required = mandatory?(field, options.delete(:required)))
          required = required_signifier if required == true
          value += " <em class='required'>#{required}</em>"
        end

        html_options.stringify_keys!
        html_options['for'] ||= "#{@object_name}_#{field}"

        if errors_for? field
          error_msg = @object.errors[field].to_a.to_sentence
          option_capitalize = options.delete(:capitalize) || capitalize_errors
          error_msg = error_msg.capitalize unless option_capitalize == 'false' or option_capitalize == false
          value += %Q( <span class="feedback">#{error_msg}.</span>)
        end

        @template.content_tag :label, value, html_options
      end

      def mandatory?(method, override = nil)
        return override unless override.nil?
        # Leverage vendor/validation_reflection.rb
        if @object.class.respond_to? :reflect_on_validations_for
          @object.class.reflect_on_validations_for(method).any? { |v| v.macro == :validates_presence_of }
        end
      end

      # Writes out a <span/> element with a hint for how to fill in a field.
      # Options:
      #  - :hint: text for the hint.  Optional.
      def hint_element(options = {})
        hint = options.delete :hint
        if hint
          @template.content_tag :span, hint, :class => 'hint'
        else
          ''
        end
      end

      # Writes out a <span/> element with something that follows a field.
      # Options:
      #  - :hint: text for the hint.  Optional.
      def addendum_element(options = {})
        addendum = options.delete :addendum
        if addendum
          @template.content_tag :span, addendum, :class => 'addendum'
        else
          ''
        end
      end

      def errors_for?(method)
        @object && @object.respond_to?(:errors) && @object.errors[method]
      end

      def output_buffer
        @template.output_buffer
      end

      def output_buffer=(buffer)
        @template.output_buffer = buffer
      end

    end
  end
end
