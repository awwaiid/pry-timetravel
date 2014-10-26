require 'rubygems'
require 'pry'

require File.expand_path('../pry-timetravel/commands', __FILE__)

class PryTimetravel
  class << self

    def dlog(msg)
      if ENV["TIMETRAVEL_DEBUG"]
        File.open("meta.log", 'a') do |file|
          file.puts("#{Time.now} [#{$$}] #{msg}")
        end
      end
    end

    at_exit do
      PryTimetravel.dlog "at_exit"
      if $root_parent && $$ != $root_parent
        PryTimetravel.dlog "Sending SIGUSR1 up to #{$root_parent}"
        Process.kill 'SIGUSR1', $root_parent
      end
    end

    def enter_suspended_animation
      old_sigcont_handler = Signal.trap('CONT') do
        dlog("Got a SIGCONT")
      end

      old_sigexit_handler = Signal.trap('EXIT') do
        dlog("got EXIT")
        Kernel.exit!
      end

      dlog("Stopping myself")
      Process.kill 'SIGSTOP', $$
      dlog("Back from SIGSTOP!")

      dlog("Returning to old SIGCONT")
      Signal.trap('CONT', old_sigcont_handler || "DEFAULT")
      dlog("Returning to old SIGEXIT")
      Signal.trap('EXIT', old_sigexit_handler || "DEFAULT")
    end

    def snapshot

      # We need a root-parent to keep the shell happy
      if ! $root_parent
        $root_parent = $$
        child_pid = fork
        if child_pid
          Signal.trap('INT') do
            dlog("root-parent got INT")
          end
          Signal.trap('USR1') do
            dlog("root-parent got USR1")
            Kernel.exit!
          end
          dlog "Root parent waiting on #{child_pid}"
          Process.waitpid child_pid
          dlog "Root parent exiting!"
          Kernel.exit!
        end
      end

      $timetravel_root ||= $$

      parent_pid = $$
      child_pid = fork
      if child_pid
        dlog("I am parent #{parent_pid}: I have a child pid #{child_pid}")

        # Method 3: Child suspends themselves, parent adds them to list
        @previous_pid ||= []
        @previous_pid.push child_pid

        # Perform operation
        yield

      else
        child_pid = $$
        dlog("I am child #{child_pid}: I have a parent pid #{parent_pid}")
        enter_suspended_animation
      end
    end

    def snapshot_list
      @previous_pid && @previous_pid.join(" ")
    end

    def restore_snapshot(target_pid = nil, count = nil)
      dlog("Thinking about time travel...");

      if target_pid.nil? && @previous_pid && ! @previous_pid.empty?
        count = 1 if count == 0
        target_pid = @previous_pid[-count]
      else
        target_pid = target_pid
      end

      if target_pid
        dlog("ME #{$$}: I found a target pid #{target_pid}! TIME TRAVEL TIME")
        Process.kill 'SIGCONT', target_pid
        enter_suspended_animation
      else
        dlog("I was unable to time travel. Maybe it is a myth.");
      end
    end

    def restore_root_snapshot
      restore_snapshot($timetravel_root) if $timetravel_root
    end

  end
end

