module Db
  module EstablishConnection
    class ReadReplica
      def self.call
        rails_env = Rails.env
        return if rails_env.test?
        env = Figaro.env
        ActiveRecord::Base.establish_connection(
          adapter: 'postgresql',
          database: "upaya_#{rails_env}",
          host: env.database_host,
          username: env.database_username,
          password: env.database_password,
        )
      end
    end
  end
end
