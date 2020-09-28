require 'rails_helper'

describe Encryption::KmsClient do
  before do
    stub_mapped_aws_kms_client(
      [
        { plaintext: 'a' * 3000, ciphertext: 'kms1', key_id: 'key1' },
        { plaintext: 'a' * 3000, ciphertext: 'kms1', key_id: 'key2' },
        { plaintext: 'a' * 3000, ciphertext: 'kms1', key_id: 'key3' },

        { plaintext: 'b' * 3000, ciphertext: 'kms2', key_id: 'key1' },
        { plaintext: 'b' * 3000, ciphertext: 'kms2', key_id: 'key2' },
        { plaintext: 'b' * 3000, ciphertext: 'kms2', key_id: 'key3' },

        { plaintext: 'c' * 3000, ciphertext: 'kms3', key_id: 'key1' },
        { plaintext: 'c' * 3000, ciphertext: 'kms3', key_id: 'key2' },
        { plaintext: 'c' * 3000, ciphertext: 'kms3', key_id: 'key3' },
      ],
    )

    encryptor = Encryption::Encryptors::AesEncryptor.new
    {
      'a' * 3000 => 'local1',
      'b' * 3000 => 'local2',
      'c' * 3000 => 'local3',
    }.each do |plaintext, ciphertext|
      allow(encryptor).to receive(:encrypt).
        with(plaintext, local_encryption_key).
        and_return(ciphertext)
      allow(encryptor).to receive(:decrypt).
        with(ciphertext, local_encryption_key).
        and_return(plaintext)
    end
    allow(Encryption::Encryptors::AesEncryptor).to receive(:new).and_return(encryptor)
    allow(FeatureManagement).to receive(:kms_multi_region_enabled?).and_return(kms_multi_region_enabled) # rubocop:disable Layout/LineLength
    allow(FeatureManagement).to receive(:use_kms?).and_return(kms_enabled)
    allow(Figaro.env).to receive(:aws_kms_region_configs).and_return(kms_region_configs.to_json)
    allow(Figaro.env).to receive(:aws_region).and_return(aws_region)
  end

  let(:plaintext) { 'a' * 3000 + 'b' * 3000 + 'c' * 3000 }
  let(:encryption_context) { { 'context' => 'attribute-bundle', 'user_id' => '123-abc-456-def' } }

  let(:local_encryption_key) do
    OpenSSL::HMAC.digest(
      'sha256',
      Figaro.env.password_pepper,
      '123-abc-456-defattribute-bundlecontextuser_id',
    )
  end

  let(:aws_region) { 'us-north-by-northwest-1' }
  let(:kms_region_configs) do
    [
      { region: 'us-north-by-northwest-1', key_id: 'key1' },
      { region: 'us-south-by-southwest-1', key_id: 'key2' },
    ]
  end

  let(:kms_multi_region_enabled) { true }

  let(:kms_regionalized_ciphertext) do
    'KMSc' + %w[kms1 kms2 kms3].map do |c|
      payload = {
        regions: {
          'us-north-by-northwest-1' => Base64.strict_encode64(c),
          'us-south-by-southwest-1' => Base64.strict_encode64(c),
        },
      }
      Base64.strict_encode64(payload.to_json)
    end.to_json
  end

  let(:kms_legacy_ciphertext) do
    'KMSc' + %w[kms1 kms2 kms3].map { |c| Base64.strict_encode64(c) }.to_json
  end

  let(:local_ciphertext) do
    'LOCc' + %w[local1 local2 local3].map { |c| Base64.strict_encode64(c) }.to_json
  end

  let(:kms_enabled) { true }

  describe '#encrypt' do
    context 'with KMS enabled' do
      context 'with multi region enabled' do
        it 'encrypts with KMS multi region' do
          result = subject.encrypt(plaintext, encryption_context)
          expect(result).to eq(kms_regionalized_ciphertext)
        end
      end
      context 'with multi region disabled' do
        let(:kms_multi_region_enabled) { false }
        before { allow(Figaro.env).to receive(:aws_kms_key_id).and_return('key1') }

        it 'encrypts with KMS legacy single region' do
          result = subject.encrypt(plaintext, encryption_context)
          expect(result).to eq(kms_legacy_ciphertext)
        end
      end
    end

    context 'with KMS disabled' do
      let(:kms_enabled) { false }

      it 'encrypts with a local key' do
        result = subject.encrypt(plaintext, encryption_context)

        expect(result).to eq(local_ciphertext)
      end
    end

    it 'logs the context' do
      expect(Encryption::KmsLogger).to receive(:log).with(:encrypt, encryption_context)

      subject.encrypt(plaintext, encryption_context)
    end
  end

  describe '#decrypt' do
    context 'with a ciphertext encrypted with KMS multi region' do
      let(:kms_multi_region_enabled) { true }
      it 'decrypts the ciphertext with KMS' do
        result = subject.decrypt(kms_regionalized_ciphertext, encryption_context)
        expect(result).to eq(plaintext)
      end
    end

    context 'with a ciphertext encrypted with a local key' do
      it 'decrypts the ciphertext with a local key' do
        result = subject.decrypt(local_ciphertext, encryption_context)

        expect(result).to eq(plaintext)
      end
    end

    context 'with a contextless ciphertext' do
      before do
        contextless_client = Encryption::ContextlessKmsClient.new
        allow(contextless_client).to receive(:decrypt).
          with('KMSx123abc').
          and_return('plaintext')
        allow(contextless_client).to receive(:decrypt).
          with('123abc').
          and_return('plaintext')
        allow(Encryption::ContextlessKmsClient).to receive(:new).and_return(contextless_client)
      end

      context 'created with KMS' do
        it 'delegates to the contextless kms client' do
          result = subject.decrypt('KMSx123abc', encryption_context)

          expect(result).to eq('plaintext')
        end
      end

      context 'created with a local key' do
        it 'delegates to the contextless kms client' do
          result = subject.decrypt('123abc', encryption_context)

          expect(result).to eq('plaintext')
        end
      end
    end

    it 'logs the context' do
      expect(Encryption::KmsLogger).to receive(:log).with(:decrypt, encryption_context)
      subject.decrypt(kms_regionalized_ciphertext, encryption_context)
    end
  end
end
