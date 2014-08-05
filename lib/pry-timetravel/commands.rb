
Pry::Commands.create_command "checkpoint", "Set a marker in the timeline" do
  match 'checkpoint'
  group 'Timetravel'
  #  description 'Snapshot the world so we can timetravel back here later'
  banner <<-'BANNER'
    Usage: checkpoint
           checkpoint --list
           checkpoint --delete [INDEX]

    This will add a checkpoint which you can return to later.
  BANNER

  #  def options(opt)
    #  opt.on :d, :delete,
      #  "Delete the checkpoint with the given index. If no index is given delete them all",
      #  :optional_argument => true, :as => Integer
    #  opt.on :l, :list,
      #  "Show all checkpoints"
  #  end
  def process
    PryTimetravel.checkpoint
  end
end

Pry::Commands.create_command "timetravel", "Set a marker in the timeline" do
  match 'timetravel'
  group 'Timetravel'
  #  description 'Snapshot the world so we can timetravel back here later'
  banner <<-'BANNER'
    Usage: checkpoint
           checkpoint --list
           checkpoint --delete [INDEX]

    This will add a checkpoint which you can return to later.
  BANNER

  #  def options(opt)
    #  opt.on :d, :delete,
      #  "Delete the checkpoint with the given index. If no index is given delete them all",
      #  :optional_argument => true, :as => Integer
    #  opt.on :l, :list,
      #  "Show all checkpoints"
  #  end
  def process
    PryTimetravel.go_back
  end
end

