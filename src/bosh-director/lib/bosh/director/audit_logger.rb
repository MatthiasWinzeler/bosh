require 'logging'

module Bosh::Director
  module AuditLogger

    DEFAULT_AUDIT_LOG_PATH = '/var/vcap/sys/log/director'.freeze

    def self.info(message)
      audit_logger.info(message)
    end

    private_class_method def self.audit_logger
      logger = Logging::Logger.new('DirectorAudit')
      audit_log = File.join(DEFAULT_AUDIT_LOG_PATH, Config.audit_filename)

      logger.add_appenders(
        Logging.appenders.file(
          'DirectorAudit',
          filename: audit_log,
          layout: ThreadFormatter.layout,
        ),
      )
      logger.level = 'debug'
      logger
    end

  end
end
