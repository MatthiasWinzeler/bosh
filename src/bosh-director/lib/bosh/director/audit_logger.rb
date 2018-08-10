require 'logging'

module Bosh::Director
  class AuditLogger

    DEFAULT_AUDIT_LOG_PATH = File.join('var', 'vcap', 'sys', 'log', 'director').freeze

    def initialize
      log_file_path = Config.audit_log_path || DEFAULT_AUDIT_LOG_PATH

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
