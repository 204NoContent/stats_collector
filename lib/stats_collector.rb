require "stats_collector/version"

module StatsCollector
end

if defined?(Rails::Railtie)
  require 'stats_collector/railtie'
elsif defined?(Rails::Initializer)
  raise "stats_collector is not compatible with Rails 2.3 or older"
end
