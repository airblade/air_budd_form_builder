AirBuddFormBuilder
==================

A form builder that generates semantic HTML as advocated by Andy Budd in [CSS Mastery][1].

It generates [Wufoo-style][2] buttons and links for submitting the form, cancelling it, etc.  These buttons and links use several icons from the [FAMFAMFAM set][3].  You can choose not to use them if you don't want to.

[1]: http://www.cssmastery.com
[2]: http://particletree.com/features/rediscovering-the-button-element/
[3]: http://famfamfam.com/lab/icons/silk/

Please send feedback to boss@airbladesoftware.com.


HAML
====
Thanks to [David Baldwin][4], this form builder can be used with HAML.

[4]: http://www.baldwindigital.net


ERB Example
===========

app/views/projects/new.html.erb:

    <% airbudd_form_for @project do |f| %>
      <%= f.text_field :title, :required => true, :name => "Article's Title" %>
      <% f.buttons do |b| %>
        <%= b.save %>
        <%= b.cancel :url => projects_path %>
      <% end %>
    <% end %>

This renders:

    <form ...> <!-- standard Rails form element -->
      <p class="text">
        <label for="article_title">Article's Title:
          <em class="required">(required)</em>
        </label>
        <input id="article_title" name="article[title]" type="text" value=""/>
      </p>
      <div class="buttons">
        <button type="submit" class="positive"><img src="/images/icons/tick.png" alt=""/> Save</button>
        <a href="/projects"><img src="/images/icons.pencil.png" alt=""/> Cancel</a>
      </div>
    </form>

And if the field's value is invalid:

    <p class="error text">
      <label for="article_title">Article's Title:
        <em class="required">(required)</em>
        <span class="feedback">can't be blank</span>
      </label>
      <input id="article_title" name="article[title]" type="text" value=""/>
    </p>

See Mr Budd's good book for discussion of the HTML and the CSS to go with it.


To Do
=====

* Fix country_select so it handles priority countries and options.  It's currently broken.
* Wrapper for options_group_from_collection_for_select.
* DRY way to show consistent form links, e.g. edit, outside a form.
  - include link_to_function, link_to_remote, etc.
  - Cf AirBlade::AirBudd::FormHelper#link_to_form.
  - Do we need to wrap buttons/links in a div?  (Probably semantically good to do so?)
* Two read-only field helpers: one for within a form, containing the value so it can be submitted, and one for the 'show' page, so we can use the same markup and CSS (c.f. http://tomayko.com/writings/administrative-debris)..
* Form-wide configuration (e.g. for suffix option).
* Example CSS:
  - for Wufoo-style buttons and links.
  - for CSS Mastery XHTML.
* Summary error messages.
* Consider how to handle multiple actions, e.g. 'save & create another', 'save & keep editing'.  See Brandon Keepers's with_action plugin: http://opensoul.org/2007/7/16/handling-forms-with-multiple-buttons


Copyright (c) 2007 Andrew Stewart, released under the MIT license.
