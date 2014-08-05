require 'rubygems'
require 'pry'

require File.expand_path('../pry-timetravel/commands', __FILE__)

class PryTimetravel
  class << self

    def dlog(msg)
      File.open("meta.log", 'a') do |file|
        file.puts(msg)
      end
    end

    def checkpoint
      parent_pid = $$
      child_pid = fork
      if child_pid
        dlog("PARENT #{parent_pid}: I have a child pid #{child_pid}")

        @previous_pid ||= []
        @previous_pid.push child_pid

        # The parent universe freezes
        #  dlog("PARENT #{$$}: I am suspending. My child is #{parent_pid}")
        #  dlog("PARENT #{$$}: suspending")
        #  Process.setpgrp
        #  Process.setsid
        #  dlog("PARENT #{$$}: resumed!")
      else
        child_pid = $$

        dlog("CHILD: #{child_pid}: I have a parent pid #{parent_pid}")

        Process.kill 'SIGSTOP', child_pid

        dlog("CHILD #{child_pid}: resumed!")
      end
    end

    def go_back
      dlog("ME #{$$}: Thinking about time travel...");
      dlog("ME #{$$}: previous_pid = #{ @previous_pid }");
      if @previous_pid && ! @previous_pid.empty?
        previous_pid = @previous_pid.pop

        dlog("ME #{$$}: I found a previous pid #{previous_pid}! TIME TRAVEL TIME")
        Process.kill 'SIGCONT', previous_pid
        dlog("ME #{$$}: I resumed pid #{previous_pid}... now time to wait")
        #  Process.waitpid(previous_pid)
        Process.waitall
        dlog("ME #{$$}: If you meet your previous self, kill yourself.")
        #  Process.kill 'SIGKILL', $$
        Kernel.exit!
      end
      dlog("ME #{$$}: I was unable to time travel. Maybe it is a myth.");
    end
  end
end

