FactoryBot.define do
  Faker::Config.locale = :en

  factory :gpo_confirmation_code do
    profile
    otp_fingerprint { Pii::Fingerprinter.fingerprint('ABCDE12345') }
  end
end
