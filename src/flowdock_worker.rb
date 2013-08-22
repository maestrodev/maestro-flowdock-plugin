
require 'flowdock'
require 'maestro_plugin'
require 'timeout'

module MaestroDev
  module Plugin

    class FlowdockWorker < Maestro::MaestroWorker
      FLOWDOCK_TIMEOUT = 60  # Seconds before we decide flowdock isn't going to respond
      FLOWDOCK_MAX_MESSAGE_LENGTH = 8096

      def post_to_flow
        validate_chat_parameters

        # create a new Flow object with target flow's api token and external user name (enough for posting to Chat)
        flow = Flowdock::Flow.new(:api_token => @api_token, :external_user_name => @nickname)

        # send message to Chat
        flowdock_push(flow, nil, @message, @tags, nil) do |flow, subject, content, tags, link|
            response = flow.push_to_chat(:content => content, :tags => tags)
            raise PluginError, 'No response received' unless response
        end
      end

      def post_to_team
        validate_team_parameters

        # create a new Flow object with target flow's api token and sender information for Team Inbox posting
        flow = Flowdock::Flow.new(:api_token => @api_token,
          :source => @source, :from => {:name => @nickname, :address => @email})

        # send message to Team Inbox
        flowdock_push(flow, @subject, @message, @tags, @link) do |flow, subject, content, tags, link|
          response = flow.push_to_team_inbox(:subject => subject,
            :content => content,
            :tags => tags, :link => link)
          raise PluginError, 'No response received' unless response
        end
      end

      private

      def validate_common_parameters
        errors = []

        @api_token = get_field('api_token', '')
        @message = get_field('message', '')
        @tags = get_field('tags')
        @nickname = get_field('nickname', '')

        errors << 'missing field api_token' if @api_token.empty?
        errors << 'missing field message' if @message.empty?

        return errors
      end

      def validate_chat_parameters
        errors = validate_common_parameters

        errors << 'missing field nickname' if !@nickname || @nickname.empty?

        raise ConfigError, "Configuration Errors: #{errors.join(', ')}" unless errors.empty?
      end

      def validate_team_parameters
        errors = validate_common_parameters

        @email = get_field('email', '')
        @subject = get_field('subject', '')
        @source = get_field('sender', get_field('source', 'Maestro'))
        @link = get_field('link')

        errors << 'missing field email' if @email.empty?
        errors << 'missing field subject' if @subject.empty?

        raise ConfigError, "Configuration Errors: #{errors.join(', ')}" unless errors.empty?
      end

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
            raise PluginError, 'Problem sending to flowdock (timeout)'
          end
        end

        write_output("Flowdock message sent, with tags: #{get_field('tags')}\n")
      end
    end
  end
end
