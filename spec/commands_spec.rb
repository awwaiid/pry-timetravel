require './spec/spec_helper'
require 'pty'
require 'expect'

pry_timetravel_cmd = "TERM=dumb pry -f --no-color --no-pager --no-history --noprompt -s timetravel"

describe "pry-timetravel" do
  it "starts with no snapshots" do
    PTY.spawn(pry_timetravel_cmd) do |reader, writer|
      writer.puts("snap --list")
      found = reader.expect(/No snapshots/,1)
      expect(found).to be_truthy
    end
  end
  it "Exits with 0 snapshots cleanly" do
    saved_pid = nil
    PTY.spawn(pry_timetravel_cmd) do |reader, writer, cmd_pid|
      saved_pid = cmd_pid
      writer.puts("snap --list")
      found = reader.expect(/No snapshots/,1)
      expect(found).to be_truthy
      writer.puts("exit")
      sleep 1 # Give time to exit?
    end

    pid_list = `ps h -o pid,ppid -g #{saved_pid}`.split(/\n/)
    expect(pid_list.count).to be == 0
  end
  it "creates one snapshot" do
    PTY.spawn(pry_timetravel_cmd) do |reader, writer, cmd_pid|
      writer.puts("snap")
      writer.puts("snap --list")

      all1, pid1 = reader.expect(/^(\d+) \(0\) <main> 1/,1)
      all2, pid2 = reader.expect(/^  (\d+) \(1\) <main> 1 \*\*\*/,1)

      expect(pid1.to_i).to be > 0
      expect(pid2.to_i).to be > 0

      pid_list = `ps h -o pid,ppid -g #{cmd_pid}`.split(/\n/)
      expect(pid_list.count).to be == 4
    end
  end

  it "Can time-travel to before a var existed" do
    PTY.spawn(pry_timetravel_cmd) do |reader, writer, cmd_pid|
      writer.puts("snap")
      writer.puts("x = 7")
      reader.expect(/^=> 7/,1)
      writer.puts("x")
      reader.expect(/^=> 7/,1)
      writer.puts("back")
      reader.expect(/^At the top level\./,1)
      writer.puts("x")
      result = reader.expect(/^NameError: undefined local variable or method `x' for main:Object/,1)
      expect(result).to be_truthy
    end
  end

  it "Can time-travel to a previous var value" do
    PTY.spawn(pry_timetravel_cmd) do |reader, writer, cmd_pid|
      writer.puts("x = 7")
      expect(reader.expect(/^=> 7/,1)).to be_truthy
      writer.puts("snap")
      writer.puts("x")
      expect(reader.expect(/^=> 7/,1)).to be_truthy
      writer.puts("snap")
      writer.puts("x = 7")
      reader.expect(/^=> 13/,1)
      writer.puts("back")
      reader.expect(/^At the top level\./,1)
      writer.puts("x")
      result = reader.expect(/^=> 7/,1)
      expect(result).to be_truthy
    end
  end

end

