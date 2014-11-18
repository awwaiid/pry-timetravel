require 'rubygems'
require 'pry'
require 'json'

require_relative 'pry-timetravel/commands'

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
      dlog("Installing SIGCONT trap")
      old_sigcont_handler = Signal.trap('CONT') do
        dlog("Got a SIGCONT")
      end

      dlog("Installing SIGEXIT trap")
      old_sigexit_handler = Signal.trap('EXIT') do
        dlog("got EXIT")
        Kernel.exit! true
      end

      dlog("Stopping myself")
      Process.kill 'SIGSTOP', $$
      dlog("Back from SIGSTOP!")

      @snap_tree = JSON.parse(File.read("/tmp/timetravel_#{$root_parent}.json"))

      dlog("Returning to old SIGCONT")
      Signal.trap('CONT', old_sigcont_handler || "DEFAULT")

      dlog("Returning to old SIGEXIT")
      Signal.trap('EXIT', old_sigexit_handler || "DEFAULT")
    end

    def start_root_parent
      $root_parent = $$
      child_pid = fork
      if child_pid
        Signal.trap('INT') do
          dlog("root-parent got INT, ignoring")
        end
        Signal.trap('USR1') do
          dlog("root-parent got USR1, exiting")
          FileUtils.rm("/tmp/timetravel_#{$root_parent}.json")
          Kernel.exit! true
        end
        dlog "Root parent waiting on #{child_pid}"
        #  sleep
        #  Process.waitall
        Process.waitpid child_pid
        #  Process.waitpid 0
        dlog "Root parent exiting after wait"
        FileUtils.rm("/tmp/timetravel_#{$root_parent}.json")
        Kernel.exit! true
      end
    end

    def snapshot(target, parent = -> {}, child = -> {})

      # We need a root-parent to keep the shell happy
      if ! $root_parent
        start_root_parent
      end

      @timetravel_root ||= $$
      @snap_tree ||= {
        $$.to_s => {
          "file" => target.eval('__FILE__'),
          "line" => target.eval('__LINE__'),
        }
      }

      parent_pid = $$
      child_pid = fork

      if child_pid

        dlog("I am parent #{parent_pid}: I have a child pid #{child_pid}")
        enter_suspended_animation

        # Perform child operation
        child.()

      else

        child_pid = $$
        dlog("I am child #{child_pid}: I have a parent pid #{parent_pid}")

        @snap_tree[child_pid.to_s] = {
          "previous" => parent_pid,
          "file" => target.eval('__FILE__'),
          "line" => target.eval('__LINE__'),
        }

        # Perform parent operation
        parent.()

      end
    end

    def snapshot_list(target, indent = "", node = @timetravel_root.to_s)
      # @snap_tree && @snap_tree.keys.join(" ")
      return unless node && node != ""

      # This shouldn't be here
      @snap_tree[$$.to_s]["file"] = target.eval('__FILE__')
      @snap_tree[$$.to_s]["line"] = target.eval('__LINE__')

      out = "#{indent}#{node} #{@snap_tree[node]["file"]} #{@snap_tree[node]["line"]} #{ node == $$.to_s ? '***' : ''}\n"
      @snap_tree.keys.select { |n|
        @snap_tree[n]["previous"] == node.to_i
      }.each do |n|
        out += snapshot_list(target, indent + "  ", n)
      end
      out
    end

    def restore_snapshot(target, target_pid = nil, count = 1)
      dlog("Thinking about time travel... $$");

      if target_pid.nil? && @snap_tree && ! @snap_tree[$$.to_s].nil?
        count = 1 if count < 1
        target_pid = @snap_tree[$$.to_s]["previous"]
        @snap_tree[$$.to_s]["file"] = target.eval('__FILE__')
        @snap_tree[$$.to_s]["line"] = target.eval('__LINE__')
      else
        target_pid = target_pid
      end

      if target_pid
        dlog("ME #{$$}: I found a target pid #{target_pid}! TIME TRAVEL TIME")

        File.open("/tmp/timetravel_#{$root_parent}.json", 'w') do |f|
          f.puts @snap_tree.to_json
        end

        Process.kill 'SIGCONT', target_pid
        enter_suspended_animation
      else
        dlog("I was unable to time travel. Maybe it is a myth.");
        puts "No previous snapshot found."
      end
    end

    def restore_root_snapshot
      restore_snapshot(@timetravel_root) if @timetravel_root
    end

  end
end

