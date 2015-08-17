require 'rspec'
require './lib/pry-timetravel'

#require 'pry/test/helper'

# in case the tests call reset_defaults, ensure we reset them to
# amended (test friendly) values
# class << Pry
#   alias_method :orig_reset_defaults, :reset_defaults
#   def reset_defaults
#     orig_reset_defaults

#     Pry.config.color = false
#     Pry.config.pager = false
#     Pry.config.should_load_rc      = false
#     Pry.config.should_load_local_rc= false
#     Pry.config.should_load_plugins = false
#     Pry.config.history.should_load = false
#     Pry.config.history.should_save = false
#     Pry.config.correct_indent      = false
#     Pry.config.hooks               = Pry::Hooks.new
#     Pry.config.collision_warning   = false
#   end
# end
# Pry.reset_defaults
