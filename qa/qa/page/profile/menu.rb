# frozen_string_literal: true

module QA
  module Page
    module Profile
      class Menu < Page::Base
        include SubMenus::CreateNewMenu
        include SubMenus::ContextSwitcher

        def click_ssh_keys
          click_element(:nav_item_link, submenu_item: 'SSH Keys')
        end

        def click_account
          click_element(:nav_item_link, submenu_item: 'Account')
        end

        def click_emails
          click_element(:nav_item_link, submenu_item: 'Emails')
        end

        def click_password
          click_element(:nav_item_link, submenu_item: 'Password')
        end

        def click_access_tokens
          click_element(:nav_item_link, submenu_item: 'Access Tokens')
        end
      end
    end
  end
end

QA::Page::Profile::Menu.prepend_mod_with('Page::Profile::Menu', namespace: QA)
