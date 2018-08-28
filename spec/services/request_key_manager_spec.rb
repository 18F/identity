require 'rails_helper'

describe RequestKeyManager do
  describe '.private_key' do
    it 'initializes' do
      ssh_key = described_class.private_key

      expect(ssh_key).to be_a OpenSSL::PKey::RSA
    end
  end

  describe '.public_key' do
    it 'initializes' do
      ssh_key = described_class.public_key

      expect(ssh_key).to be_a OpenSSL::PKey::RSA
    end
  end
end
