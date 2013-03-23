require 'rubygems'
require 'flowdock'
require 'maestro_agent'
require 'timeout'


module MaestroDev
  class FlowdockWorker < Maestro::MaestroWorker
    FLOWDOCK_TIMEOUT = 60  # Seconds before we decide flowdock isn't going to respond

    def validate_input_fields(fields)
      workitem['fields']['__error__'] = ''
      fields.each do |field|
        workitem['fields']['__error__'] += "Missing Field #{field}, " if workitem['fields'][field].nil? or workitem['fields'][field].to_s.empty?
      end
      if !workitem['fields']['body'].nil? && workitem['fields']['body'].length > 140
        workitem['fields']['__error__'] = 'Invalid body, over 140 chars'
      end
    end

    def post_to_flow
      begin
        write_output("Validating Flowdock task inputs\n")
        validate_input_fields(['nickname','api_token','message'])
        return unless workitem['fields']['__error__'].empty?
      
        # create a new Flow object with target flow's api token and external user name (enough for posting to Chat)
        flow = Flowdock::Flow.new(:api_token => get_field('api_token'), :external_user_name => get_field('nickname'))

        ##
        # Accommodate an HTTPS proxy setting
        if proxy = ENV['HTTPS_PROXY']
          proxy = URI.parse(proxy)
          Flowdock::Flow.http_proxy proxy.host, proxy.port
        end

        # send message to Chat
        flowdock_push(flow) do |flow|
            response = flow.push_to_chat(:content => get_field('message'), :tags => get_field('tags'))
            raise Exception.new unless response
        end
        write_output("Flowdock message #{get_field('message')} sent, with tags: #{get_field('tags')}\n")
      rescue Exception => e
        set_error("Failed to post flowdock message #{e}")
      end
    end
    
    def post_to_team
      begin
        write_output("Validating Flowdock task inputs\n")
        validate_input_fields(['api_token','message','email','subject'])
        return unless workitem['fields']['__error__'].empty?
      
        # create a new Flow object with target flow's api token and sender information for Team Inbox posting
        flow = Flowdock::Flow.new(:api_token => get_field('api_token'),
          :source => (get_field('sender')||get_field('source')||'Maestro'), :from => {:name => get_field('nickname'), :address => get_field('email')})

        ##
        # Accommodate an HTTPS proxy setting
        if proxy = ENV['HTTPS_PROXY']
          proxy = URI.parse(proxy)
          Flowdock::Flow.http_proxy proxy.host, proxy.port
        end

        # send message to Team Inbox
        flowdock_push(flow) do |flow|
          response = flow.push_to_team_inbox(:subject => get_field('subject'),
            :content => get_field('message'),
            :tags => get_field('tags'), :link => get_field('link'))
          raise Exception.new unless response
        end
        write_output("Flowdock message #{get_field('message')} sent\n")
      rescue Exception => e
        set_error("Failed to post flowdock message #{e}")
      end      
    end
    
    private

    # Done so tests can override this (essentially static) variable
    def flowdock_timeout
      FLOWDOCK_TIMEOUT
    end

    def flowdock_push(flow)
      begin
        Timeout::timeout(flowdock_timeout) {
          yield(flow)
        }
      rescue Timeout::Error
        write_output("Timeout after #{FLOWDOCK_TIMEOUT} seconds sending to flowdock, retrying...");

        begin
          Timeout::timeout(flowdock_timeout) {
            yield(flow)
          }
        rescue Timeout::Error
          write_output("Second Timeout after #{FLOWDOCK_TIMEOUT} seconds sending to flowdock, aborting");
          raise Exception.new("Problem sending to flowdock (timeout)");
        end
      end
    end
  end
end