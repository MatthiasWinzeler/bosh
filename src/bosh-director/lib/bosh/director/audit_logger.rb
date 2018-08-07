require 'logging'

module Bosh::Director
  class AuditLogger

    DEFAULT_AUDIT_LOG_PATH = '/var/vcap/sys/log/director'.freeze

    def initialize
      @logger = Logging::Logger.new('DirectorAudit')
      audit_log = File.join(DEFAULT_AUDIT_LOG_PATH, Config.audit_filename)

      @logger.add_appenders(
        Logging.appenders.file(
          'DirectorAudit',
          filename: audit_log,
          layout: ThreadFormatter.layout,
        ),
      )
      @logger.level = 'debug'
    end

    def info(message)
      @logger.info(message)
    end

  end
end
