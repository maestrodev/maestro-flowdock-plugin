
require 'flowdock'
require 'maestro_plugin'
require 'timeout'

module MaestroDev
  module FlowdockPlugin
    class FlowdockException < StandardError
    end
  
    class FlowdockWorker < Maestro::MaestroWorker
      FLOWDOCK_TIMEOUT = 60  # Seconds before we decide flowdock isn't going to respond
      FLOWDOCK_MAX_MESSAGE_LENGTH = 8096
  
      def validate_input_fields(fields)
        error_message = ''
        fields.each do |field|
          field_value = get_field(field)
          error_message << "Missing Field #{field}, " if field_value.nil? or field_value.to_s.empty?
        end
        set_error(error_message)
      end
  
      def post_to_flow
        validate_input_fields(['nickname','api_token','message'])
        return unless error.empty?
  
        # create a new Flow object with target flow's api token and external user name (enough for posting to Chat)
        flow = Flowdock::Flow.new(:api_token => get_field('api_token'), :external_user_name => get_field('nickname'))
  
        # send message to Chat
        flowdock_push(flow, nil, get_field('message'), get_field('tags'), nil) do |flow, subject, content, tags, link|
            response = flow.push_to_chat(:content => content, :tags => tags)
            raise FlowdockException.new("No response received") unless response
        end
      rescue Exception => e
        set_error("Failed to post flowdock message #{e}")
      end
      
      def post_to_team
        validate_input_fields(['api_token','message','email','subject'])
        return unless error.empty?
  
        # create a new Flow object with target flow's api token and sender information for Team Inbox posting
        flow = Flowdock::Flow.new(:api_token => get_field('api_token'),
          :source => (get_field('sender')||get_field('source')||'Maestro'), :from => {:name => get_field('nickname'), :address => get_field('email')})
  
        # send message to Team Inbox
        flowdock_push(flow, get_field('subject'), get_field('message'), get_field('tags'), get_field('link')) do |flow, subject, content, tags, link|
          response = flow.push_to_team_inbox(:subject => subject,
            :content => content,
            :tags => tags, :link => link)
          raise FlowdockException.new("No response received") unless response
        end
      rescue Exception => e
        set_error("Failed to post flowdock message #{e}")
      end
      
      private
  
      # Done so tests can override this (essentially static) variable
      def flowdock_timeout
        FLOWDOCK_TIMEOUT
      end
  
      def flowdock_push(flow, subject, content, tags, link)
        ##
        # Accommodate an HTTPS proxy setting
        if (proxy = ENV['HTTPS_PROXY'])
          proxy = URI.parse(proxy)
          Flowdock::Flow.http_proxy proxy.host, proxy.port
        end
  
        if content.length() > FLOWDOCK_MAX_MESSAGE_LENGTH
          content = "#{content[0..(FLOWDOCK_MAX_MESSAGE_LENGTH - 3)]}..."
        end
  
        begin
          Timeout::timeout(flowdock_timeout) {
            write_output("Sending to flowdock...\n")
            yield(flow, subject, content, tags, link)
          }
        rescue Timeout::Error
          write_output("Timeout after #{FLOWDOCK_TIMEOUT} seconds sending to flowdock, retrying...\n")
  
          begin
            Timeout::timeout(flowdock_timeout) {
              yield(flow, subject, content, tags, link)
            }
          rescue Timeout::Error
            write_output("Second Timeout after #{FLOWDOCK_TIMEOUT} seconds sending to flowdock, aborting\n")
            raise FlowdockException.new('Problem sending to flowdock (timeout)')
          end
        end
  
        write_output("Flowdock message sent, with tags: #{get_field('tags')}\n")
      end
    end
  end
end
