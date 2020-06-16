require 'rails_helper'

describe Acuant::Responses::GetResultsResponse do
  context 'with a successful result' do
    let(:http_response) do
      instance_double(
        Faraday::Response,
        body: AcuantFixtures.get_results_response_success,
      )
    end

    subject(:response) { described_class.new(http_response) }

    it 'returns a successful response with no errors' do
      expect(response.success?).to eq(true)
      expect(response.errors).to eq([])
      expect(response.exception).to be_nil
    end

    it 'parsed PII from the doc' do
      # The PII from the response fixture
      expect(response.pii_from_doc).to eq(
        first_name: 'JANE',
        middle_name: nil,
        last_name: 'DOE',
        address1: '1000 E AVENUE E',
        city: 'BISMARCK',
        state: 'ND',
        zipcode: '58501',
        dob: '03/31/1984',
        state_id_number: 'DOE-84-1165',
        state_id_jurisdiction: 'ND',
        state_id_type: 'drivers_license',
        phone: nil,
      )
    end
  end

  context 'with a failed result' do
    let(:http_response) do
      instance_double(
        Faraday::Response,
        body: AcuantFixtures.get_results_response_failure,
      )
    end

    subject(:response) { described_class.new(http_response) }

    it 'returns an unsuccessful response with errors' do
      expect(response.success?).to eq(false)
      expect(response.errors).to eq(
        # This is the error message for the error in the response fixture
        [I18n.t('friendly_errors.doc_auth.document_type_could_not_be_determined')],
      )
      expect(response.exception).to be_nil
    end

    it 'does not parse any PII from the doc' do
      expect(response.pii_from_doc).to eq({})
    end
  end
end
