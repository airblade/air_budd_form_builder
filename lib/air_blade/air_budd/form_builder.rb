module AirBlade
  module AirBudd

    class FormBuilder < ActionView::Helpers::FormBuilder
      include Haml::Helpers if defined? Haml       # for compatibility
      include ActionView::Helpers::TextHelper      # so we can use concat
      include ActionView::Helpers::CaptureHelper   # so we can use capture

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
      # <p>
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
      # <p class="error">
      #   <label for="article_title">Article's Title:
      #     <em class="required">(required)</em>
      #     <span class="feedback">can't be blank</span>
      #   </label>
      #   <input id="article_title" name="article[title]" type="text" value=""/>
      #   <span class="hint">Try not to use the letter 'e'.</span>
      # </p>
      def self.create_field_helper(field_helper)
        src = <<-END
          def #{field_helper}(method, options = {}, html_options = {})
            @template.content_tag('p',
              label_element(method, options, html_options) +
                super(method, options) +
                hint_element(options),
              (@object.errors[method].nil? ? {} : {:class => 'error'})
            )
          end
        END
        class_eval src, __FILE__, __LINE__
      end

      # TODO: DRY this with self.create_field_helper above.
      def self.create_collection_field_helper(field_helper)
        src = <<-END
          def #{field_helper}(method, choices, options = {}, html_options = {})
            @template.content_tag('p',
              label_element(method, options, html_options) +
                super(method, choices, options) +
                hint_element(options),
              (@object.errors[method].nil? ? {} : {:class => 'error'})
            )
          end
        END
        class_eval src, __FILE__, __LINE__
      end

      # Beefs up the appropriate field helpers.
      %w( text_field text_area password_field file_field
          date_select country_select check_box radio_button ).each do |name|
        create_field_helper name
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
        content = capture(self, &block)
        concat '<div class="buttons">', block.binding
        concat content, block.binding
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
      def button(purpose = :save, options = {})
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
        attributes_for_element = {:class => nature}.merge(element == :button  ?
                                                          {:type => 'submit'} :
                                                          {:href => (options[:url] || '')} )
        # TODO: separate button and link construction and use
        # link_to to gain its functionality, e.g. :back?
        @template.content_tag(element.to_s,
                              legend,
                              attributes_for_element)
      end

      def method_missing(*args, &block)
        if args.first.to_s =~ /^(new|save|cancel|edit|delete)$/
          button args.shift, *args, &block
        else
          super
        end
      end

      private

      # Writes out a <label/> element for the given field.
      # Options:
      #  - :required: true if field is mandatory, false otherwise (default)
      #  - :label: text wrapped by the <label/>.  Optional (default is field's name).
      #  - :suffix: appended to the label.  Optional (default is ':').
      #  - :capitalize: false if any error message should not be capitalised,
      #    true otherwise.  Optional (default is true).
      def label_element(field, options = {}, html_options = {})
        text = options.delete(:label) || field.to_s.humanize
        suffix = options.delete(:suffix) || ':'
        value = text + suffix
        value += ' <em class="required">(required)</em>' if options.delete(:required)

        html_options.stringify_keys!
        html_options['for'] ||= "#{@object_name}_#{field}"

        unless @object.errors[field].blank?
          error_msg = @object.errors[field].to_a.to_sentence
          option_capitalize = options.delete :capitalize
          error_msg = error_msg.capitalize unless option_capitalize == 'false' or option_capitalize == false
          value += %Q( <span class="feedback">#{error_msg}.</span>)
        end

        @template.content_tag :label, value, html_options
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
    end

  end
end
