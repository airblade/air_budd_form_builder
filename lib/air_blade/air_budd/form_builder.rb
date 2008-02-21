module AirBlade
  module AirBudd

    class FormBuilder < ActionView::Helpers::FormBuilder
      include ActionView::Helpers::TextHelper      # so we can use concat
      include ActionView::Helpers::CaptureHelper   # so we can use capture

      # Creates a glorified form field helper.  It takes a form helper's usual
      # arguments with an optional options hash:
      #
      # <%= form.text_field 'title', :required => true, :label => "Article's Title" %>
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
      # </p>
      def self.create_field_helper(field_helper)
        src = <<-END
          def #{field_helper}(method, options = {}, html_options = {})
            @template.content_tag('p',
              label_element(method, options, html_options) +
              super(method, options),
              (@object.errors[method].nil? ? {} : {:class => 'error'})
            )
          end
        END
        class_eval src, __FILE__, __LINE__
      end

      # Beefs up the appropriate field helpers.
      %w( text_field text_area password_field file_field
          country_select select check_box radio_button ).each do |name|
        create_field_helper name
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
      #     <%= b.save 'Update' %>
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
      # type = :save|:cancel|:edit|:delete
      # TODO :new|:all ?
      #
      # Options you can use are:
      #   :label - The label for the button or text for the link.
      #            Optional; defaults to capitalised purpose.
      #   :icon  - Whether or not to show an icon to the left of the label.
      #            Optional; icon will be shown unless :icon set to false.
      #   :url   - The URL to link to (only used in links).
      #            Optional; defaults to ''.
      def button(purpose = :save, options = {})
        element, icon, nature = case purpose
                                when :save   then [:button, 'tick',       'positive']
                                when :cancel then [:a,      'arrow_undo', nil       ]
                                when :edit   then [:a,      'pencil',     nil       ]
                                when :delete then [:button, 'cross',      'negative']
                                end
        legend = ( (options[:icon] == false || options[:icon] == 'false') ?
                   '' :
                   "<img src='/images/icons/#{icon}.png' alt=''></img> " ) +
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
        if args.first.to_s =~ /^(save|cancel|edit|delete)$/
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
      def label_element(field, options = {}, html_options = {})
        value = "#{options.delete(:label) || field.to_s.humanize}:"
        value += ' <em class="required">(required)</em>' if options.delete(:required)

        html_options.stringify_keys!
        html_options['for'] ||= "#{@object_name}_#{field}"

        unless @object.errors[field].blank?
          value += %Q( <span class="feedback">#{@object.errors[field].to_a.to_sentence.capitalize}.</span>)
        end

        @template.content_tag :label, value, html_options
      end
    end

  end
end
