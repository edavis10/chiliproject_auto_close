require 'redmine'

Redmine::Plugin.register :chiliproject_auto_close do
  name 'Auto Close'
  author 'Eric Davis'
  url 'https://projects.littlestreamsoftware.com/projects/chiliproject_auto_close'
  author_url 'http://www.littlestreamsoftware.com'
  description 'Automatically close old issues'
  version '0.1.0'

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
