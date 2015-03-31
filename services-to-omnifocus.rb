#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "appscript"
require "optparse"

def its
  Appscript.its
end

def update_if_changed(task, field, value)
  current_value = task.send(field).get
  current_value = current_value.to_date if current_value.is_a?(Time)

  if current_value != value
    puts "Updating field #{field} of task #{task.name.get}"
    task.send(field).set value
  end
end

$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: services-to-omnifocus.rb [options]"
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  opts.on('-v', '--verbose', 'Run verbosely') do |v|
    $options[:verbose] = v
  end
  opts.on('-d', '--development', 'Run in development mode, taking plugins from plugins_develop/') do |d|
    $options[:develop] = d
  end
end.parse!

$omnifocus = Appscript.app('OmniFocus').default_document

plugin_dir = File.join(File.dirname(File.expand_path(__FILE__)), 
                   ($options[:develop] ? 'plugins_develop' : 'plugins'))
Dir.glob(File.join(plugin_dir, '*.rb')).each do |plugin|
  puts 'Processing "%s" plugin' % File.basename(plugin, '.rb') if $options[:verbose]
  require plugin
end

$omnifocus.synchronize
