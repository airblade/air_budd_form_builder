module AirBlade
  module AirBudd

    # TODO: fieldset, summary error message.
    class FormBuilder < ActionView::Helpers::FormBuilder

      # Creates a glorified form field helper.  It takes a form helper's usual
      # arguments with an optional options hash:
      #
      # <%= form.text_field 'title', :required => true, :name => "Article's Title" %>
      #
      # The code above generates the following HTML.  The :required entry in the hash
      # triggers the <em/> element and the :name overwrites the default field name,
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
              (@object.errors.any? ? {:class => 'error'} : {})
            )
          end
        END
        class_eval src, __FILE__, __LINE__
      end

      # Beefs up the field helpers where sensible.
      (field_helpers - %w(label check_box radio_button fields_for)).each do |name|
        create_field_helper name
      end

      private

      # Writes out a <label/> element for the given field.
      # Options:
      #  - :required: true if field is mandatory, false otherwise (default)
      #  - :value: text wrapped by the <label/>.  Optional (default is field's name).
      def label_element(field, options = {}, html_options = {})
        value = "#{options.delete(:value) || field.to_s.humanize}:"
        value += ' <em class="required">(required)</em>' if options.delete(:required)

        html_options.stringify_keys!
        html_options['for'] ||= "#{@object_name}_#{field}"

        unless @object.errors[field].blank?
          value += %Q( <span class="feedback">#{@object.errors[field].to_a.to_sentence}</span>)
        end

        @template.content_tag :label, value, html_options
      end
    end

  end
end
