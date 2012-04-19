require 'rubygems'
require 'flowdock'
require 'maestro_agent'


module MaestroDev
  class FlowdockWorker < Maestro::MaestroWorker
    
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

        # send message to Chat
        response = flow.push_to_chat(:content => get_field('message'), :tags => get_field('tags'))
        raise Exception.new unless response
        
        write_output("Flowdock message #{get_field('message')} sent\n")
      rescue Exception => e
        set_error("Failed to post flowdock message #{e}")
      end
    end
    
    def post_to_team
      begin
        write_output("Validating Flowdock task inputs\n")
        validate_input_fields(['api_token','message','source','email','subject'])
        return unless workitem['fields']['__error__'].empty?
      
        # create a new Flow object with target flow's api token and sender information for Team Inbox posting
        flow = Flowdock::Flow.new(:api_token => get_field('api_token'),
          :source => get_field('source'), :from => {:name => get_field('nickname'), :address => get_field('email')})

        # send message to Team Inbox
        response = flow.push_to_team_inbox(:subject => get_field('subject'),
          :content => get_field('message'),
          :tags => get_field('tags'), :link => get_field('link'))
        raise Exception.new unless response
        
        write_output("Flowdock message #{get_field('message')} sent\n")
      rescue Exception => e
        set_error("Failed to post flowdock message #{e}")
      end      
    end
    
  end
end