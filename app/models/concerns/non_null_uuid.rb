# Default populates a uuid field with a v4 UUID.
module NonNullUuid
  extend ActiveSupport::Concern

  included { before_create :generate_uuid }

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
