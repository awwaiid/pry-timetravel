require 'rubygems'
require 'pry'

require File.expand_path('../pry-timetravel/commands', __FILE__)

class PryTimetravel
  class << self

    def dlog(msg)
      #  File.open("meta.log", 'a') do |file|
        #  file.puts(msg)
      #  end
    end

    def checkpoint
      parent_pid = $$
      child_pid = fork
      if child_pid
        dlog("PARENT #{parent_pid}: I have a child pid #{child_pid}")

        # Method 1: Child suspends themselves, parent adds them to list
        #  @previous_pid ||= []
        #  @previous_pid.push child_pid

        # Method 2: Parent does a global-blocking waitall
        # when the child exits, we can continue
        # Problem: What if the child exits in a bad way? Check out '$?'
        Process.waitpid(child_pid)
        dlog("ME #{$$}: Previous exit: #{$?.inspect}")
        if $?.exitstatus != 42
          # Since this wasn't a timetravel return, we must unravel this world
          Kernel.exit! $?.exitstatus
        end

        # The parent universe freezes
        #  dlog("PARENT #{$$}: I am suspending. My child is #{parent_pid}")
        #  dlog("PARENT #{$$}: suspending")
        #  Process.setpgrp
        #  Process.setsid
        #  dlog("PARENT #{$$}: resumed!")
      else
        child_pid = $$
        dlog("CHILD: #{child_pid}: I have a parent pid #{parent_pid}")

        # Method 1: Child suspends themselves, parent adds them to list
        # The child is eventually resumed
        #  Process.kill 'SIGSTOP', child_pid
        #  dlog("CHILD #{child_pid}: resumed!")

        # Method 2: Parent does a global-blocking waitall
        # Child doesn't need to keep track of parent at all?
        # Child will just exit! when it is done
        @previous_pid ||= []
        @previous_pid.push parent_pid

      end
    end

    def go_back
      dlog("ME #{$$}: Thinking about time travel...");
      dlog("ME #{$$}: previous_pid = #{ @previous_pid }");
      if @previous_pid && ! @previous_pid.empty?
        previous_pid = @previous_pid.pop
        dlog("ME #{$$}: I found a previous pid #{previous_pid}! TIME TRAVEL TIME")

        # Method 1: Awaken the child and let them take over
        # Main parent can't exit or shell will get upset, so wait for all children
        # Once all children are done, kill ourself
        #  Process.kill 'SIGCONT', previous_pid
        #  dlog("ME #{$$}: I resumed pid #{previous_pid}... now time to wait")
        #  #  Process.waitpid(previous_pid)
        #  Process.waitall
        #  dlog("ME #{$$}: If you meet your previous self, kill yourself.")
        #  #  Process.kill 'SIGKILL', $$
        #  Kernel.exit!

        # Method 2: Kill ourself and let the parent take over
        # The parent was just doing a waitpid, so it is ready
        #  Process.kill 'SIGKILL', $$
        Process.exit! 42

      end
      dlog("ME #{$$}: I was unable to time travel. Maybe it is a myth.");
    end
  end
end

