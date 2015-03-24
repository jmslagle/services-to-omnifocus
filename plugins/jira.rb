#
# Create OmniFocus tasks for cards assigned to you in Jira.
#

require 'jira'

JIRA_PROJECTS = ENV['JIRA_PROJECTS']
JIRA_USERNAME = ENV['JIRA_USERNAME']
JIRA_CLOSED = ENV['JIRA_CLOSED'].split(/,\s*/)
JIRA_SITE = ENV['JIRA_SITE']
JIRA_CONTEXT = ENV['JIRA_CONTEXT']


#JIRA_JQL_CLOSED = " and status not in ( #{JIRA_CLOSED.join(',')} )"

options = {
  :username     => ENV['JIRA_USERNAME'],
  :password     => ENV['JIRA_PASSWORD'],
  :site         => JIRA_SITE,
  :context_path => JIRA_CONTEXT,
  :auth_type    => :basic,
}


puts "Connecting to Jira at :#{ENV['JIRA_SITE']}:#{ENV['JIRA_CONTEXT']}:"

jira = JIRA::Client.new(options)

project = $omnifocus.flattened_projects["JIRA"].get

JIRA_PROJECTS.split(/,\s*/).each do |jproject|
  puts "Processing JIRA Project #{jproject}"
  issues = jira.Issue.jql("project=#{jproject} and assignee=#{JIRA_USERNAME}")
  issues.each do |iss|
    puts "Issue #{iss.key} - #{iss.summary} - #{iss.status.name}" if $options[:verbose]
    task_id = "[%s]" % iss.key
    taskurl = "#{JIRA_SITE}#{JIRA_CONTEXT}/browse/#{iss.key}"
    task = project.tasks[its.name.contains(task_id)].first.get rescue nil
    if task
      next if task.completed.get # Don't support transitioning on the other end
      next if task.completed.get && JIRA_CLOSED.include?(iss.status.name)
      if JIRA_CLOSED.include? iss.status.name
        puts "Completing in OmniFocus: #{iss.key}: #{iss.summary}"
        task.completed.set true
      else
        update_if_changed task, :note, taskurl
        update_if_changed task, :name, "[%s] %s" % [iss.key, iss.summary]
      end
    elsif !JIRA_CLOSED.include?(iss.status.name)
      puts "Adding: " + iss.key
      task = project.make :new => :task, :with_properties => {
        :name => "[%s] %s" % [iss.key, iss.summary],
        :note => taskurl,
      }
    end
  end
end
