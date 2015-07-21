module Installer
  class Updater < SitePrism::Page
    set_url '/system/index.php'

    section :install_success, Installer::Success, 'body'

    element :header, 'h1'
    element :req_title, 'h1 .req-title'
    element :error, 'div.issue'

    elements :inline_errors, '.setting-field em'
  end
end
