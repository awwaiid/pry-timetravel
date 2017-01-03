require 'rubygems'
require 'pry'
require 'json'

require_relative 'pry-timetravel/commands'

# = Timetravel!
#
# This is a pry plugin that keeps a pool of fork()ed process checkpoints, so
# that you can jump "back in time" to a previous place in your execution.
#
# == Forking Model
#
# When you create a snapshot, fork() is executed. The parent (original) process
# is suspended, and the new child process picks up where that left off.
class PryTimetravel
  class << self

    def dlog(msg)
      if ENV["TIMETRAVEL_DEBUG"]
        File.open("meta.log", 'a') do |file|
          file.puts("#{Time.now} [#{$$}] #{msg}")
        end
      end
    end

    # TODO: Should probably delay calling this until first snapshot
    at_exit do
      PryTimetravel.dlog "at_exit"
      if $root_parent && $$ != $root_parent
        PryTimetravel.dlog "Sending SIGUSR1 up to #{$root_parent}"
        Process.kill 'SIGUSR1', $root_parent
      end
    end

    def enter_suspended_animation
      dlog("Suspend: Installing SIGCONT trap")
      old_sigcont_handler = Signal.trap('CONT') do
        dlog("Got a SIGCONT")
      end

      dlog("Suspend: Installing SIGEXIT trap")
      old_sigexit_handler = Signal.trap('EXIT') do
        dlog("got EXIT")
        Kernel.exit! true
      end

      dlog("Suspend: Stopping myself")
      Process.kill 'SIGSTOP', $$

      dlog("Resume: Back from SIGSTOP! Loading snapshot tree")
      load_global_timetravel_state

      dlog("Resume: Returning to old SIGCONT")
      Signal.trap('CONT', old_sigcont_handler || "DEFAULT")

      dlog("Resume: Returning to old SIGEXIT")
      Signal.trap('EXIT', old_sigexit_handler || "DEFAULT")
    end

    # The root parent is a sort of overseer of the whole tree, and something
    # that is still alive and waiting for any signals from the outside world.
    #
    # Once any time travel starts, the parent forks and waits for its one and only direct child. All the other action happens in that child and its own children.
    #
    # If you USR1 this root parent, it will try to clean up the entire tree.
    #
    # It ignores INT, so that if you ^C the process it won't die so quickly.
    def start_root_parent
      $root_parent = $$
      child_pid = fork
      if child_pid
        Signal.trap('INT') do
          dlog("Root-parent: Got INT, ignoring")
        end
        Signal.trap('USR1') do
          dlog("Root-parent: Got USR1, exiting")
          cleanup_global_timetravel_state
          Kernel.exit! true
        end
        dlog "Root parent: Waiting on child pid #{child_pid}"
        Process.waitpid child_pid
        dlog "Root parent: Exiting after wait"
        cleanup_global_timetravel_state
        FileUtils.rm("/tmp/timetravel_#{$root_parent}.json")
        Kernel.exit! true
      end
    end

    def auto_snapshot(target)
      if !@do_trace
        @trace = TracePoint.new(:line) do |tp|
          # puts "trace status: #{$in_trace}"
          if !$in_trace
            $in_trace = true
            # puts "path: #{File.expand_path(tp.path)}"
            # puts "snapshotting trace"
            # if ! (tp.defined_class.to_s =~ /Pry/)
            # if tp.path =~ /<main>/
            # if tp.path =~ /<main>/
            #   p [tp.path, tp.lineno, tp.event, tp.defined_class, Dir.pwd] # , tp.raised_exception]
            # end
            # if tp.path.include?(Dir.pwd) || tp.path =~ /<main>/
            if File.expand_path(tp.path).include?(Dir.pwd)
              p [tp.path, tp.lineno, tp.event, tp.defined_class, Dir.pwd] # , tp.raised_exception]
              # p caller
            # if tp.path =~ /<main>/
            #   # p tp
            #   p [tp.path, tp.lineno, tp.event] # , tp.raised_exception]
              PryTimetravel.snapshot(
                tp.binding,
                # now_do:        -> { run(args.join(" ")) unless args.empty? },
                # on_return_do:  -> { run('whereami') }
              )
            # end
            end
            $in_trace = false
          end
        end
        @trace.enable
        @do_trace = true
      else
        @trace.disable
        @do_trace = false
      end
    end

    def update_current_snapshot_info(target, parent_pid = nil)
      my_pid = $$.to_s
      @snap_tree ||= {}
      @snap_tree[my_pid] ||= {}
      @snap_tree[my_pid]["file"]   = target.eval('__FILE__')
      @snap_tree[my_pid]["line"]   = target.eval('__LINE__')
      @snap_tree[my_pid]["time"]   = Time.now.to_f
      @snap_tree[my_pid]["id"]     = @id
      @snap_tree[my_pid]["previous"] = parent_pid if parent_pid
    end

    def snapshot(target, opts = {})
      opts[:now_do] ||= -> {}
      opts[:on_return_do]  ||= -> {}

      # We need a root-parent to keep the shell happy
      if ! $root_parent
        start_root_parent
      end

      @id ||= 0
      @timetravel_root ||= $$
      update_current_snapshot_info(target)
      @id += 1

      parent_pid = $$
      child_pid = fork

      if child_pid

        dlog("Snapshot: I am parent #{parent_pid}. I have a child pid #{child_pid}. Now suspending.")
        enter_suspended_animation

        dlog("Snapshot: Back from suspended animation. Running on_return_do.")
        # Perform operation now that we've come back
        opts[:on_return_do].()

      else

        child_pid = $$
        dlog("Snapshot: I am child #{child_pid}. I have a parent pid #{parent_pid}")

        update_current_snapshot_info(target, parent_pid)

        # Perform immediate operation
        dlog("Snapshot: Running now_do.")
        opts[:now_do].()

      end
    end

    def snapshot_list(target, indent = "", node = @timetravel_root.to_s, my_indent = nil)
      if node == ""
        return "No snapshots"
      end
      return unless node && node != ""

      # Freshen the current snapshot so it looks right
      update_current_snapshot_info(target)

      code_line = IO.readlines(@snap_tree[node]["file"])[@snap_tree[node]["line"].to_i - 1].chomp

      out = "#{my_indent || indent}#{node} (#{@snap_tree[node]["id"]}) #{@snap_tree[node]["file"]} #{@snap_tree[node]["line"]} #{ node == $$.to_s ? '***' : ''} #{code_line}\n"
      children = @snap_tree.keys.select { |n| @snap_tree[n]["previous"] == node.to_i }
      if children.length == 1
        out += snapshot_list(target, indent, children[0])
      else
        children.each { |n|
          out += snapshot_list(target, indent + "  ", n, indent + "> ")
        }
      end
      # @snap_tree.keys.select { |n|
      #   @snap_tree[n]["previous"] == node.to_i
      # }.each do |n|
        # out += snapshot_list(target, indent + "  ", n)
      # end
      out
    end

    def restore_snapshot(target, target_pid = nil)
      dlog("Restore: Trying to restore,");

      if target_pid.nil? && @snap_tree && ! @snap_tree[$$.to_s].nil?
        target_pid = @snap_tree[$$.to_s]["previous"]
      else
        target_pid = target_pid
      end

      if target_pid && @snap_tree[target_pid.to_s]
        dlog("Restore: I found a target pid #{target_pid}! TIME TRAVEL TIME")

        # Update our current information of our current running snapshot
        update_current_snapshot_info(target)

        save_global_timetravel_state

        # Bring our target back to life
        Process.kill 'SIGCONT', target_pid

        # Go to sleeeeeeeppppp
        enter_suspended_animation
      else
        dlog("Restore: I was unable to time travel. Maybe it is a myth.");
        puts "No previous snapshot found."
      end
    end

    def restore_root_snapshot
      restore_snapshot(@timetravel_root) if @timetravel_root
    end

    def global_timetravel_state_filename
      "/tmp/timetravel_#{$root_parent}.json"
    end

    def save_global_timetravel_state
      File.open(global_timetravel_state_filename, 'w') do |f|
        global_state = {
          snap_tree: @snap_tree,
          do_trace: @do_trace
        }
        f.puts global_state.to_json
      end
    end

    def load_global_timetravel_state
      global_state = JSON.parse(File.read(global_timetravel_state_filename))
      @snap_tree = global_state["snap_tree"]
      @do_trace  = global_state["do_trace"]
      dlog("Loaded: " + @snap_tree.to_json)
      @id = (@snap_tree.values.map{|snap| snap['id']}.max || 0) + 1
    end

    def cleanup_global_timetravel_state
      FileUtils.rm(global_timetravel_state_filename)
    end

  end
end

