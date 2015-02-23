#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

shared_examples_for 'error response' do |code, id, provided_message = nil|
  let(:expected_message) {
    provided_message || message
  }

  it { expect(last_response.status).to eq(code) }

  describe 'response body' do
    subject { JSON.parse(last_response.body) }

    it { expect(subject['errorIdentifier']).to eq("urn:openproject-org:api:v3:errors:#{id}") }

    describe 'message' do
      it { expect(subject['message']).to include(expected_message) }

      it 'includes punctuation' do
        expect(subject['message']).to match(/(\.|\?|\!)\z/)
      end
    end
  end
end

shared_examples_for 'invalid render context' do |message|
  it_behaves_like 'error response',
                  400,
                  'InvalidRenderContext',
                  message
end

shared_examples_for 'invalid request body' do |message|
  it_behaves_like 'error response',
                  400,
                  'InvalidRequestBody',
                  message
end

shared_examples_for 'parse error' do |message|
  it_behaves_like 'invalid request body',
                  I18n.t('api_v3.errors.parse_error')

  it {
    expect(last_response.body).to be_json_eql(message.to_json)
      .at_path('_embedded/details/parseError')
  }
end

shared_examples_for 'unauthenticated access' do
  it_behaves_like 'error response',
                  401,
                  'MissingPermission',
                  I18n.t('api_v3.errors.code_401')
end

shared_examples_for 'unauthorized access' do
  it_behaves_like 'error response',
                  403,
                  'MissingPermission',
                  I18n.t('api_v3.errors.code_403')
end

shared_examples_for 'not found' do
  before do
    unless defined?(id) && defined?(type)
      message = <<MESSAGE
  Required to have specified:
    * id
    * type
  You can use 'let' for that.
MESSAGE

      raise message
    end
  end

  it_behaves_like 'error response',
                  404,
                  'NotFound' do

    let(:message) { I18n.t('api_v3.errors.code_404', type: type, id: id) }
  end
end

shared_examples_for 'update conflict' do
  it_behaves_like 'error response',
                  409,
                  'UpdateConflict',
                  I18n.t('api_v3.errors.code_409')
end

shared_examples_for 'constraint violation' do
  it_behaves_like 'error response',
                  422,
                  'PropertyConstraintViolation'
end

shared_examples_for 'format error' do |message|
  it_behaves_like 'error response',
                  422,
                  'PropertyFormatError',
                  message
end

shared_examples_for 'read-only violation' do |attribute|
  describe 'details' do
    subject { JSON.parse(last_response.body)['_embedded']['details'] }

    it { expect(subject['attribute']).to eq(attribute) }
  end

  it_behaves_like 'error response',
                  422,
                  'PropertyIsReadOnly',
                  I18n.t('api_v3.errors.writing_read_only_attributes')
end

shared_examples_for 'multiple errors' do |code, message|
  it_behaves_like 'error response',
                  code,
                  'MultipleErrors',
                  I18n.t('api_v3.errors.multiple_errors')
end

shared_examples_for 'multiple errors of the same type' do |error_count, id|
  subject { JSON.parse(last_response.body)['_embedded']['errors'] }

  it { expect(subject.count).to eq(error_count) }

  it 'has child errors of expected type' do
    subject.each do |error|
      expect(error['errorIdentifier']).to eq("urn:openproject-org:api:v3:errors:#{id}")
    end
  end
end

shared_examples_for 'multiple errors of the same type with details' do |expected_details, expected_detail_values|
  let(:errors) { JSON.parse(last_response.body)['_embedded']['errors'] }
  let(:details) { errors.each_with_object([]) { |error, l| l << error['_embedded']['details'] }.compact }

  subject do
    details.inject({}) do |h, d|
      h.merge(d) { |_, old, new| Array(old) + Array(new) }
    end
  end

  it { expect(subject.keys).to match_array(Array(expected_details)) }

  it 'contains all expected values' do
    Array(expected_details).each do |detail|
      expect(subject[detail]).to match_array(Array(expected_detail_values[detail]))
    end
  end
end

shared_examples_for 'multiple errors of the same type with messages' do
  let(:errors) { JSON.parse(last_response.body)['_embedded']['errors'] }
  let(:actual_messages) { errors.each_with_object([]) { |error, l| l << error['message'] }.compact }

  before do
    raise "Need to have 'message' defined to state\
           which message is expected".squish unless defined?(message)
  end

  it { expect(actual_messages).to match_array(Array(message)) }
end
