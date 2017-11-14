require 'logger'

module Logging

  @loggers = {}

  class << self
    def logger_for(classname)
      @loggers[classname] ||= _configure_logger_for(classname)
    end

    def _configure_logger_for(classname)
      Logger.new(STDOUT, progname: classname)
    end
  end

  module ClassMethods
    def logger
      Logging.logger_for(self.name)
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def logger
    Logging.logger_for(self.class.name)
  end

end
