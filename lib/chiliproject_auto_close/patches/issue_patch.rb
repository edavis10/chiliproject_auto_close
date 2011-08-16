module ChiliprojectAutoClose
  module Patches
    module IssuePatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
        end
      end

      module ClassMethods
        def auto_close(options={})
          options[:warning_days] ||= 60
          options[:close_days] ||= 30
          if options[:status].present?
            status_filter = []
            options[:status].to_s.split(',').each do |status_option|
              status_option.strip!
              status = IssueStatus.find_by_name(status_option)
              # Cast to int to guard against comparing string to int column (PGError)
              status ||= IssueStatus.find_by_id(status_option.to_i)
              status_filter << status.id if status.present?
            end
          else
            status_filter = IssueStatus.all.collect(&:id)
          end

          Issue.open.all(:include => :journals,
                         :conditions => ["#{Issue.table_name}.status_id in (?) AND #{Issue.table_name}.updated_on < (?) AND #{Journal.table_name}.notes LIKE '%Auto-close-id%'",
                                         status_filter, options[:close_days].to_i.days.ago]).each do |issue|
            issue.auto_close
          end

          Issue.open.all(:include => :journals,
                         :conditions => ["#{Issue.table_name}.status_id in (?) AND #{Issue.table_name}.updated_on < (?) AND #{Journal.table_name}.notes NOT LIKE '%Auto-close-id%'",
                                         status_filter, options[:warning_days].to_i.days.ago]).each do |issue|
            issue.add_auto_close_warning
          end
          
        end
        
      end

      module InstanceMethods
        def add_auto_close_warning
          closing_user_id = Setting.plugin_chiliproject_auto_close['close_user']
          if closing_user_id.present?
            closing_user = User.find_by_id(closing_user_id)
          end
          closing_user ||= User.anonymous

          message = Setting.plugin_chiliproject_auto_close['warning_note']
          message = "Auto closing issue warning" unless message.present?
          message << "\n\nAuto-close-id: #{Time.now.to_i}"
          self.journal_notes = message
          self.journal_user = closing_user
          save
                       
        end

        def auto_close
          closing_user_id = Setting.plugin_chiliproject_auto_close['close_user']
          if closing_user_id.present?
            closing_user = User.find_by_id(closing_user_id)
          end
          closing_user ||= User.anonymous

          message = Setting.plugin_chiliproject_auto_close['closing_note']
          message = "Auto closing issue" unless message.present?
          message << "\n\nAuto-close-id: #{Time.now.to_i}"
          self.journal_notes = message
          self.journal_user = closing_user
          self.status_id = Setting.plugin_chiliproject_auto_close['closing_status'] || IssueStatus.first(:conditions => {:is_closed => true})
          save
        end
        
      end
    end
  end
end
