
module Cloc

  class << self
    # Whether to warn of various things (parsing/linking problems).
    attr_accessor :warn
    alias warn? warn
  end

  autoload :Database, 'cloc/database'
  autoload :Linker, 'cloc/linker'
  autoload :FileSource, 'cloc/filesource'

end
