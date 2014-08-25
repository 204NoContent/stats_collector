require 'socket'
require 'timeout'
require 'rest_client'

module StatsCollector
  module HttpClient
    begin
      @config = YAML.load_file("#{Rails.root}/config/stats.yml")[Rails.env].with_indifferent_access
    rescue
    end
    @mutex = Mutex.new
    @batched_data = []

    class << self
      def enqueue(data)
        @mutex.synchronize do
          @batched_data << data
        end
      end

      def start
        Thread.new do
          loop do
            sleep(10)
            if @config && @config[:url] && @config[:api_key]
              post_data! unless @batched_data.empty?
            else
              @mutex.synchronize do
                @batched_data.clear
              end
            end
          end
        end
      end

      private
        def post_data!
          data = @mutex.synchronize do
            @batched_data.pop(@batched_data.length)
          end
          Thread.new do
            RestClient.post(@config[:url], { data: data.to_json }, { 'x-api-key' => @config[:api_key] })
          end
        end

    end
  end
end

StatsCollector::HttpClient.start
