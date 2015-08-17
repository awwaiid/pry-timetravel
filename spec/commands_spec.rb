require './spec/spec_helper'
require 'pty'
require 'expect'

# pry_timetravel_cmd = "pry -f -e 'Pry.config.correct_indent=false;' --no-pager --no-history --noprompt -s timetravel"
pry_timetravel_cmd = "TERM=dumb pry -f --no-color --no-pager --no-history --noprompt -s timetravel"

def strip_ansi(str)
  str.gsub(/\e\[[0-9;]*[a-zA-Z]/, '')
end

def get_line(pry_read)
  # puts "ignore1: [#{strip_ansi(pry_read.gets.chomp)}]"
  # puts "ignore2: [#{strip_ansi(pry_read.gets.chomp)}]"
  result = pry_read.gets.chomp
  puts "result: [#{result}]"
  result
  result = pry_read.gets.chomp
  puts "result: [#{result}]"
  result
  # strip_ansi(pry_read.gets.chomp)
  # strip_ansi(result)
end


describe "pry-timetravel" do
  it "starts with no snapshots" do
    PTY.spawn(pry_timetravel_cmd) do |reader, writer|
      writer.puts("snap --list")
      found = reader.expect(/No snapshots/)
      expect(found).to be_truthy
    end
  end
  it "creates one snapshot" do
    PTY.spawn(pry_timetravel_cmd) do |reader, writer, cmd_pid|
      writer.puts("snap")
      writer.puts("snap --list")

      all1, pid1 = reader.expect(/^(\d+) <main> 1/)
      all2, pid2 = reader.expect(/^  (\d+) <main> 1 \*\*\*/)

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
      writer.puts("x")
      result = reader.expect(/^NameError: undefined local variable or method `x' for main:Object/,1)
      expect(result).to be_truthy
    end
  end
  # it "creates one snapshot"  # it "forks a child" do
  #   PTY.spawn(pry_timetravel_cmd) do |pry_read, pry_write, pid|
  #     pry_write.puts "5+5"
  #     expect(strip_ansi(pry_read.gets.chomp)).to eq("5+5") # input
  #     expect(strip_ansi(pry_read.gets.chomp)).to eq("5+5") # echo
  #     expect(strip_ansi(pry_read.gets.chomp)).to eq("5+5=> 10")
  #   end
  # end
  # it "forks a child" do
  #   ReplTester.start do
  #     input '5+5'
  #     output '10'
  #   end
  # end
end

