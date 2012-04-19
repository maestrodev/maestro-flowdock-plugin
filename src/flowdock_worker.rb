require 'rubygems'
require 'flowdock'
require 'maestro_agent'


module MaestroDev
  class FlowdockWorker < MaestroWorker
    
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
      write_output("Validating Flowdock task inputs\n")
      validate_input_fields(['nickname','api_tocken','message'])
      return unless workitem['fields']['__error__'].empty?
      
      post_to_flow(get_field('message'), workitem.get_field('tags'), workitem.get_field('api_token'), workitem.get_field('nickname'))
    end
    
    def post_to_flow(message, tags, api_token, username)      
      # create a new Flow object with target flow's api token and external user name (enough for posting to Chat)
      flow = Flowdock::Flow.new(:api_token => api_token, :external_user_name => username)

      # send message to Chat
      flow.push_to_chat(:content => message, :tags => tags)
    end
    
  end
end