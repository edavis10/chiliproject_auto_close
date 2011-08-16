require File.dirname(__FILE__) + '/../../../../test_helper'

class ChiliprojectAutoClose::Patches::IssueTest < ActionController::TestCase

  context "#auto_close" do
    setup do
      configure_plugin
      @project = Project.generate!
      Timecop.travel(65.days.ago) do
        @issue_to_warn = Issue.generate_for_project!(@project, :subject => 'warn')
        @issue_to_warn.reload
        assert_equal 1, @issue_to_warn.journals.count
      end

      # 35 days since updated/added the auto close warning
      Timecop.travel(35.days.ago) do
        @issue_to_close = Issue.generate_for_project!(@project, :subject => 'close')
        @issue_to_close.add_auto_close_warning
        assert_equal 2, @issue_to_close.journals.count
      end
      Setting.clear_cache
      
    end
    
    context "issues that haven't been updated within the warning_days" do
      should "add a journal with the auto-close note" do
        assert_difference("@issue_to_warn.journals.count") do
          Issue.auto_close
        end
      end
      
      should "add note content based on the configured settings" do
        Issue.auto_close

        @issue_to_warn.reload
        assert_equal 2, @issue_to_warn.journals.count
        assert_match /been dormant/, @issue_to_warn.journals.last.notes
      end
      
      should "add note from the configured user" do
        Issue.auto_close

        @issue_to_warn.reload
        assert_equal 2, @issue_to_warn.journals.count
        assert_equal closing_user, @issue_to_warn.journals.last.user
      end

      should "add the auto-close tracking id to the note" do
        Issue.auto_close

        @issue_to_warn.reload
        assert_equal 2, @issue_to_warn.journals.count
        
        assert_match /Auto-close-id/, @issue_to_warn.journals.last.notes
      end
        
      should "not add an auto-close note if one exists" do
        @issue_to_warn.add_auto_close_warning
        
        assert_no_difference("@issue_to_warn.journals.count") do
          Issue.auto_close
        end

      end
      
    end

    context "issues with an auto-close note" do
      should "close issues that are past close_days" do
        assert_difference("@issue_to_close.journals.count",1) do
          Issue.auto_close
        end
        @issue_to_close.reload

        assert_equal 3, @issue_to_close.journals.count
        last_journal = @issue_to_close.last_journal
        assert_equal @closing_user.id, last_journal.user_id
        assert_match /no activity/, last_journal.notes
        assert @issue_to_close.closed?
      end

      should "do nothing to issues that are within the close_days" do
        @issue_not_ready_to_close = Issue.generate_for_project!(@project, :updated_on => 29.days.ago)
        @issue_not_ready_to_close.add_auto_close_warning

        assert_no_difference("@issue_not_ready_to_close.journals.count") do
          Issue.auto_close
        end
      end
    end

    context "options" do
      should "allow restricting by status ids"
      should "allow restricting by status names"
      should "allow configuring the warning_days"
      should "allow configuring the close_days"
    end
    
  end
  
end
