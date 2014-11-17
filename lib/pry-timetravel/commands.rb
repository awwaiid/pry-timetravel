
Pry::Commands.create_command "snap", "Create a snapshot that you can later return to" do
  match 'snap'
  group 'Timetravel'
  banner <<-'BANNER'
    Usage: snap [cmd]
           snap --list

    This will add a snapshot which you can return to later.
    
    If you provide [cmd] then that command will also be run -- nice for "snap next" in conjunction with pry-byebug.
  BANNER

  def options(opt)
    #  opt.on :d, :delete=,
      #  "Delete the snapshot with the given index. If no index is given delete them all",
      #  :optional_argument => true, :as => Integer
    opt.on :l, :list,
      "Show a list of existing snapshots"
  end
  def process
    if opts.l?
      output.puts PryTimetravel.snapshot_list
    else
      PryTimetravel.snapshot(
        -> { run(args.join(" ")) unless args.empty? },
        -> { run('whereami') }
      )
      #  run('whereami')
    end
  end
end

Pry::Commands.create_command "back", "Go back to the most recent snapshot" do
  match 'back'
  group 'Timetravel'
  banner <<-'BANNER'
    Usage: back [count]
           back --pid pid
           back --home

    Go back to a previous snapshot.
  BANNER

  def options(opt)
    opt.on :p, :pid=, "Jump (back) to a specific snapshot identified by [pid]",
      :as => Integer
    opt.on :home, "Jump to the end of the original execution sequence"
  end
  def process
    if opts.h?
      PryTimetravel.restore_root_snapshot
    else
      count = args.first.to_i
      PryTimetravel.restore_snapshot(opts[:p], count)
    end
  end
end

