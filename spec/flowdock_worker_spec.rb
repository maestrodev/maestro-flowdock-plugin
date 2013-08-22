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

describe MaestroDev::Plugin::FlowdockWorker do

  before(:each) do
    Maestro::MaestroWorker.mock!
  end

  after(:each) do
    workitem = nil
  end

  describe 'post_to_flow' do

    it 'should error when missing config' do
      workitem = {'fields' => {}}
      subject.perform(:post_to_flow, workitem)
      subject.error.should include('missing field message')
      subject.error.should include('missing field api_token')
      subject.error.should include('missing field nickname')
    end

    it 'should send a message' do
      workitem = {'fields' => {'message' => 'testing',
                                       'nickname' => 'bob',
                                       'api_token' => '15551212'}}

      flow = double(:flow)
      flow.stub(:push_to_chat => true)
      flow.should_receive(:push_to_chat).once
      Flowdock::Flow.stub(:new => flow)
      
      subject.perform(:post_to_flow, workitem)
      subject.error.should be_nil
    end


    it 'should deal with timeout conditions' do
      workitem = {'fields' => {'message' => 'testing',
                                       'nickname' => 'bob',
                                       'api_token' => '15551212'}}
      subject.stub(:flowdock_timeout => 1)

      flow = double(:flow)
      flow.stub(:push_to_chat) { sleep 60 }
      
      Flowdock::Flow.stub(:new => flow)
      
      subject.perform(:post_to_flow, workitem)
      subject.error.should include 'Problem sending to flowdock (timeout)'
    end
  end

  describe 'post_to_team' do

    it 'should error when missing config' do
      workitem = {'fields' => {}}
      subject.perform(:post_to_team, workitem)
      subject.error.should include('missing field api_token')
      subject.error.should include('missing field message')
      subject.error.should include('missing field subject')
      subject.error.should include('missing field email')
    end

    it 'should send a message' do
      workitem = {'fields' => {'message' => 'testing',
                               'nickname' => 'bob',
                               'api_token' => '15551212',
                               'email' => 'dev@maestrodev.com',
                               'subject' => 'test'}}

      flow = double(:flow)
      flow.stub(:push_to_team_inbox => true)
      flow.should_receive(:push_to_team_inbox).once
      Flowdock::Flow.stub(:new => flow)

      subject.perform(:post_to_team, workitem)
      subject.error.should be_nil
    end
  end
end
