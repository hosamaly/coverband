# frozen_string_literal: true

module Coverband
  class Background
    @semaphore = Mutex.new
    @thread = nil

    def self.stop
      return unless @thread

      @semaphore.synchronize do
        if @thread
          @thread.exit
          @thread = nil
        end
      end
    end

    def self.running?
      @thread.nil? ? false : @thread.alive?
    end

    def self.start
      return if running?

      logger = Coverband.configuration.logger
      @semaphore.synchronize do
        return if running?

        logger.debug("Coverband: Starting background reporting") if Coverband.configuration.verbose
        sleep_seconds = Coverband.configuration.background_reporting_sleep_seconds.to_i
        @thread = Thread.new {
          loop do
            Coverband.report_coverage
            view_tracker = Coverband.configuration.view_tracker
            view_tracker.report_views_tracked unless view_tracker.nil?
            if Coverband.configuration.reporting_wiggle
              sleep_seconds = Coverband.configuration.background_reporting_sleep_seconds.to_i + rand(Coverband.configuration.reporting_wiggle.to_i)
            end
            if Coverband.configuration.verbose
              logger.debug("Coverband: background reporting coverage (#{Coverband.configuration.store.type}). Sleeping #{sleep_seconds}s")
            end
            sleep(sleep_seconds.to_i)
          end
        }
      end
    end
  end
end
