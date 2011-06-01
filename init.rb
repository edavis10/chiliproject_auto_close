require 'redmine'

Redmine::Plugin.register :chiliproject_auto_close do
  name 'Chiliproject Auto Close plugin'
  author 'Author name'
  description 'This is a plugin for ChiliProject'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  settings(:partial => 'settings/auto_close',
           :default => {
             'close_user' => nil,
             'warning_note' => "This issue has been dormant for 60 days and will be closed in 30 days.",
             'closing_note' => "This issue has had no activity for 90 days and is now closed."
           })

end
require 'dispatcher'
Dispatcher.to_prepare :chiliproject_auto_close do

  require_dependency 'issue'
  Issue.send(:include, ChiliprojectAutoClose::Patches::IssuePatch)
end
