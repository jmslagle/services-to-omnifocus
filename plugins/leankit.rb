#
# Create OmniFocus tasks for cards assigned to you in LeanKit.
#

require 'leankitkanban'
require 'pry'

LEANKIT_USERNAME = ENV['LEANKIT_USERNAME']
LEANKIT_BOARDS = ENV['LEANKIT_BOARDS'].split(/,\s*/)
LEANKIT_USERID = ENV['LEANKIT_USERID']
LEANKIT_ACCOUNT = ENV['LEANKIT_ACCOUNT']

leankit_donelanes = ENV['LEANKIT_DONELANES'].split(/,\s*/)

LeanKitKanban::Config.email = ENV['LEANKIT_USERNAME']
LeanKitKanban::Config.password = ENV['LEANKIT_PASSWORD']
LeanKitKanban::Config.account = LEANKIT_ACCOUNT

project = $omnifocus.flattened_projects["LeanKit"].get

def is_assigned_to?(card, user)
  card["AssignedUsers"].each do |u|
    if u["Id"].to_s == user
      return true
    end
  end
  return false
end

LEANKIT_BOARDS.each do |board|
  b = LeanKitKanban::Board.find(board)
  # Iterate to get all done lanes
  b[0]["Lanes"].each do |lane|
    if leankit_donelanes.include?(lane["Id"].to_s)
      leankit_donelanes += lane["ChildLaneIds"].map(&:to_s)
    end
  end

  # Iterate again to work
  b[0]["Lanes"].each do |lane|
    lane["Cards"].each do |card|
      next if !is_assigned_to?(card, LEANKIT_USERID)
      cardid = "[%s]" % card["Id"]
      cardurl = "https://#{LEANKIT_ACCOUNT}.leankit.com/Boards/View/#{board}/#{card["Id"]}"
      puts "Card #{card["Id"]} - #{card["Title"]} - #{lane["Title"]}" if $options[:verbose]
      task = project.tasks[its.name.contains(cardid)].first.get rescue nil
      if task
        next if task.completed.get # No back updates
        if leankit_donelanes.include?(lane["Id"].to_s)
          puts "Completing in OmniFocus: #{card["Title"]} - #{cardid}"
          task.completed.set true
        else
          update_if_changed task, :note, cardurl
          update_if_changed task, :name, "#{card["Title"]} - #{cardid}"
        end
      elsif !leankit_donelanes.include?(lane["Id"].to_s)
        puts "Adding: #{card["Title"]} - #{cardid}"
        task = project.make :new => :task, :with_properties => {
          :name => "#{card["Title"]} - #{cardid}",
          :note => cardurl,
        }
      end
    end
  end

end

