require 'rails_helper'

RSpec.describe Reports::AgencyInvoiceIssuerSupplementReport do
  subject(:report) { Reports::AgencyInvoiceIssuerSupplementReport.new }

  describe '#call' do
    it 'is empty with no data' do
      expect(report.call).to eq('[]')
    end

    context 'with data' do
      let(:user) { create(:user) }
      let(:iaa_range) { Date.new(2021, 1, 1)..Date.new(2021, 12, 31) }
      let(:sp) do
        create(
          :service_provider,
          iaa: SecureRandom.hex,
          iaa_start_date: iaa_range.begin,
          iaa_end_date: iaa_range.end,
        )
      end

      before do
        create(
          :monthly_sp_auth_count,
          user: user,
          service_provider: sp,
          ial: 1,
          auth_count: 11,
          year_month: iaa_range.begin.strftime('%Y%m'),
        )
        create(
          :monthly_sp_auth_count,
          user: user,
          service_provider: sp,
          ial: 2,
          auth_count: 22,
          year_month: iaa_range.begin.strftime('%Y%m'),
        )
      end

      it 'totals up auth counts within IAA window by month' do
        result = JSON.parse(report.call, symbolize_names: true)

        expect(result).to eq(
          [
            {
              issuer: sp.issuer,
              iaa: sp.iaa,
              iaa_start_date: '2021-01-01',
              iaa_end_date: '2021-12-31',
              year_month: '202101',
              ial1_total_auth_count: 11,
              ial2_total_auth_count: 22,
            },
          ],
        )
      end
    end
  end
end
