# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'activemessaging'

task :default => 'test:run'

PROJ.name = 'activemessaging'
PROJ.version = ActiveMessaging::VERSION
PROJ.authors = 'John-Mason P. Shackelford'
PROJ.email = 'jpshack@gmail.com'
PROJ.url = 'http://code.google.com/p/ActiveMessaging/wiki/ActiveMessaging'
PROJ.rubyforge.name = 'ActiveMessaging'

PROJ.spec.opts << '--color'

# EOF
