# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#  http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'spec_helper'

describe MaestroDev::FlowdockWorker do

  before(:each) do
    Maestro::MaestroWorker.mock!
    @testee = MaestroDev::FlowdockWorker.new
  end

  after(:each) do
    workitem = nil
  end

  describe 'post_to_flow' do

    it 'should error when no message is supplied' do
      workitem = {'fields' => {'nickname' => 'bob',
                               'api_token' => '15551212'}}
      @testee.stub(:workitem => workitem)
      @testee.post_to_flow
      @testee.error.should include('Missing Field message')
    end

    it 'should error when body is too large' do
      body = <<EOS
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Na pretium odio in odio elementum at bibendum urna sagittis. Maecenas ut purus sed.
EOS
      workitem = {'fields' => {'nickname' => 'bob',
                               'api_token' => '15551212',
                               'message' => 'test',
                               'body' => body }}
      @testee.stub(:workitem => workitem)
      @testee.post_to_flow
      @testee.error.should == 'Invalid body, over 140 chars'
    end
    
    it 'should send a message' do
      workitem = {'fields' => {'message' => 'testing',
                                       'nickname' => 'bob',
                                       'api_token' => '15551212'}}
      @testee.stub(:workitem => workitem)
      
      flow = double(:flow)
      flow.stub(:push_to_chat => true)
      flow.should_receive(:push_to_chat).once
      Flowdock::Flow.stub(:new => flow)
      
      @testee.post_to_flow
      @testee.error.empty?.should be true

    end


    it 'should deal with timeout conditions' do
      workitem = {'fields' => {'message' => 'testing',
                                       'nickname' => 'bob',
                                       'api_token' => '15551212'}}
      @testee.stub(:workitem => workitem)
      @testee.stub(:flowdock_timeout => 1)

      flow = double(:flow)
      flow.stub(:push_to_chat) { sleep 60 }
      
      Flowdock::Flow.stub(:new => flow)
      
      @testee.post_to_flow
      @testee.error.should == 'Failed to post flowdock message Problem sending to flowdock (timeout)'
    end
  end

  describe 'post_to_team' do

    it 'should error when no email is supplied' do
      workitem = {'fields' => {'nickname' => 'bob',
                               'api_token' => '15551212'}}
      @testee.stub(:workitem => workitem)
      @testee.post_to_team
      @testee.error.should include('Missing Field message')
    end

    it 'should error when no email is supplied' do
      workitem = {'fields' => {'nickname' => 'bob',
                               'api_token' => '15551212',
                               'subject' => 'test'}}
      @testee.stub(:workitem => workitem)
      @testee.post_to_team
      @testee.error.should include('Missing Field email')
    end

    it 'should error when no subject is supplied' do
      workitem = {'fields' => {'nickname' => 'bob',
                               'api_token' => '15551212',
                               'email' => 'dev@maestrodev.com'}}
      @testee.stub(:workitem => workitem)
      @testee.post_to_team
      @testee.error.should include('Missing Field subject')
    end

    it 'should send a message' do
      workitem = {'fields' => {'message' => 'testing',
                               'nickname' => 'bob',
                               'api_token' => '15551212',
                               'email' => 'dev@maestrodev.com',
                               'subject' => 'test'}}
      @testee.stub(:workitem => workitem)

      flow = double(:flow)
      flow.stub(:push_to_team_inbox => true)
      flow.should_receive(:push_to_team_inbox).once
      Flowdock::Flow.stub(:new => flow)

      @testee.post_to_team
      @testee.error.empty?.should be true

    end
  end
end
