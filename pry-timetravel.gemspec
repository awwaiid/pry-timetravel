Gem::Specification.new do |s|
  s.name          = 'pry-timetravel'
  s.version       = '0.0.3'
  s.summary       = 'Timetravel'
  s.description   = 'Allows you to timetravel!'
  s.homepage      = 'https://github.com/awwaiid/pry-timetravel'
  s.email         = ['awwaiid@thelackthereof.org']
  s.authors       = ['Brock Wilcox']
  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

  s.add_dependency 'pry'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry-byebug'
  #  s.add_development_dependency 'yard'
  #  s.add_development_dependency 'redcarpet'
  #  s.add_development_dependency 'capybara'
end
