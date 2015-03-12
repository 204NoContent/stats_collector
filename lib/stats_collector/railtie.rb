require 'stats_collector'

module StatsCollector
  class Railtie < Rails::Railtie
    class << self; attr_reader :git_info; end
    @git_info = {
      :branch => (File.exists?("BRANCH") ? File.read("BRANCH").chomp : 'Unknown'),
      :revision => (File.exists?("REVISION") ? File.read("REVISION").chomp : 'Unknown'),
    }

    initializer 'stats_collector' do |app|
      require 'stats_collector/http_client'
      self.class.subscribe_to_action_controller_notifications

      ActiveSupport.on_load :action_controller do
        StatsCollector::Railtie.add_tracking
        StatsCollector::Railtie.add_standard_info_to_payload
      end
    end

    def add_tracking
      ActionDispatch::Request.module_eval do
        attr_reader :events, :people

        old_initialize = self.instance_method(:initialize)
        define_method(:initialize) do |env|
          old_initialize.bind(self).call(env)
          @events = []
          @people = {}
        end

        old_headers = self.instance_method(:headers)
        define_method(:headers) do
          h = old_headers.bind(self).call
          h['X-42Floors-Revision'] = StatsCollector::Railtie.git_info[:revision]
          h['X-42Floors-Branch'] = StatsCollector::Railtie.git_info[:branch]
          h
        end

        def track(name, options = {})
          @events << { name: name, options: options }
        end

        def identify(person, type = :user)
          @people[type.downcase.to_sym] = person
        end
      end
    end

    def add_standard_info_to_payload
      ActionController::Base.class_eval do
        def append_info_to_payload(payload)
          super
          session[:init] = true
          payload[:session_id] = session[:session_id] || session.id
          namespace = self.class.to_s.deconstantize
          payload[:controller_namespace] = namespace.empty? ? 'None' : namespace
          payload[:referrer_url] = request.referrer
          payload[:url] = request.original_url
          payload[:host] = request.host
          payload[:short_path] = request.path
          payload[:ip] = request.headers['X-Forwarded-For'].try(:split, ',').try(:first)
          payload[:user_agent] = request.env["HTTP_USER_AGENT"]
          payload[:branch] = request.headers['X-Test-Branch']
          payload[:server] = request.headers['X-Test-Server']
          payload[:events] = request.events
          payload[:people] = request.people
        rescue
        end
      end
    end

    def subscribe_to_action_controller_notifications
      ActiveSupport::Notifications.subscribe /process_action.action_controller/ do |name, start, finish, id, payload|
        unless payload[:exception]
          data = {
            app_name: Rails.application.class.parent_name,
            controller: payload[:controller],
            controller_namespace: payload[:controller_namespace],
            action: payload[:action],
            url: payload[:url],
            full_path: payload[:path], # note: payload[:path] is set by defalt to be request.full_path
            path: payload[:short_path],
            host: payload[:host],
            params: payload[:params],
            method: payload[:method],
            status_code: payload[:status],
            time: start.utc,
            total_time: ((finish - start) * 1000),
            view_time: payload[:view_runtime],
            db_time: payload[:db_runtime],
            session_id: payload[:session_id],
            referrer_url: payload[:referrer_url],
            ip: payload[:ip],
            user_agent: payload[:user_agent],
            branch: payload[:branch],
            server: payload[:server],
            events: payload[:events],
            people: payload[:people]
          }

          StatsCollector::HttpClient.enqueue(data)
        end
      end
    end

  end
end
