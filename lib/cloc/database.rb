
module Cloc

  HOME = ENV['HOME'] ? File.expand_path('~') : Dir.pwd

  class Database

    # Find all existing versions.
    def self.versions
      @versions ||= Dir.entries(HOME).grep(/^.cloc-(.*)/) { $1 }.sort
    end

    # Pick a default version.
    #
    # We give preference to RUBY_VERSION.
    def self.default_version
      versions.include?(RUBY_VERSION) ? RUBY_VERSION : (versions.first || RUBY_VERSION)
    end

    def initialize(version)
      @version = version
      @table = {}
      load if File.exist? path
    end

    def version; @version; end

    def merge(hash)
      @table.merge!(hash) do |key, oldval, newval|
        oldval.merge(newval)
      end
    end

    def data
      @table
    end

    def path
      File.join(HOME, ".cloc-#{@version}")
    end

    def save
      File.open(path, 'w') { |f| Marshal.dump(@table, f) }
    end

    def load
      @table = File.open(path) { |f| Marshal.load(f) }
    end
  end

end
