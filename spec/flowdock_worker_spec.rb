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

  describe 'send_sms()' do
    before(:each) do
      @testee = MaestroDev::FlowdockWorker.new
    end

    after(:each) do
      workitem = nil
    end

    it 'should error with no message' do
      workitem = {'fields' => {"nickname" => "bob",
                               "api_token" => "15551212"}}
      @testee.stub(:workitem).and_return(workitem)
  
  
   
      @testee.post_to_flow
      workitem['fields']['__error__'].should include('Missing Field body')
    end
    
    it 'should send a message' do
      workitem = {"fields" => {"message" => "testing",
                                       "nickname" => "bob",
                                       "api_token" => "15551212"}}
      @testee.stub(:workitem).and_return(workitem)

      @testee.post_to_flow
      workitem['fields']['__error__'].should eql('')
    end
  end
end
