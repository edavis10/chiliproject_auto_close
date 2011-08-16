namespace :auto_close do
  desc <<-END_DESC
Automatically close issues.

Options:
  status           Names or ids of issue statuses to close. (Default: all)
  warning_days     Number of days before a warning is added. (Default: 60)
  close_days       Number of days after a warning before closing. (Default: 30)

Examples:
  rake auto_close:close
  rake auto_close:close status=1,2
  rake auto_close:close status=1,2,"Open","In Progress" close_days=10

END_DESC
  task :close => :environment do
    options = {
      :status => ENV['status'],
      :warning_days => ENV['warning_days'],
      :close_days => ENV['close_days']
    }
    
    Issue.auto_close(options)
  end
end
