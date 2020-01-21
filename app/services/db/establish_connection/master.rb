module Db
  module EstablishConnection
    class Master
      def self.call
        env = Figaro.env
        rails_env = Rails.env
        ActiveRecord::Base.establish_connection(
          adapter: 'postgresql',
          database: rails_env.production? ? env.database_name : "upaya_#{rails_env}",
          host: env.database_host,
          username: env.database_username,
          password: env.database_password,
        )
      end
    end
  end
end
