require 'logging'

module Bosh::Director
  class AuditLogger

    def initialize
      log_file_path = Config.audit_log_path

      @logger = Logging::Logger.new('DirectorAudit')
      @logger.level = 'debug'
      @logger.add_appenders(
        Logging.appenders.file(
          'DirectorAudit',
          filename: File.join(log_file_path, Config.audit_filename),
          layout: ThreadFormatter.layout,
        ),
      )
    end

    def info(message)
      @logger.info(message)
    end

  end
end
