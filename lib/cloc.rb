
module Cloc

  class << self
    attr :warn
    alias warn? warn
  end

  autoload :Database, 'cloc/database'
  autoload :Linker, 'cloc/linker'
  autoload :FileSource, 'cloc/filesource'

end
