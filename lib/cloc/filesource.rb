
module Cloc

  class NmNtFnd < Exception
  end

  class FileSource

    def initialize(pathname)
      @pathname = pathname
      @c2r_cache = {}
    end

    def raw_source
      @raw_source ||= IO.read(@pathname).gsub!(/\r?\n|\r/, "\n").freeze
    end

    # Returns the source after processing it a bit to make it easier
    # for other parsing functions to not care about edge cases.
    def source
      return @source if defined? @source

      @source = raw_source.dup
      @source.gsub!('rb_define_global_function(', 'rb_define_module_function(rb_mKernel,')
      @source.gsub!('define_filetest_function(', 'rb_define_singleton_method(rb_cFile,')

      # Add any special cases here. As an example, here are some
      # "macro expansions" required to process DataObjects extensions.
      @source.gsub!('CONST_GET(rb_mKernel,', 'rb_path2class(')
      @source.gsub!('SQLITE3_CLASS(', 'rb_define_class_under(mSqlite3,');
      @source.gsub!('DRIVER_CLASS(', 'rb_define_class_under(mDOMysql,');

      @source.freeze
    end

    # Converts a character offset to a line number.
    def offs_to_line(offs)
      # The following isn't as inefficient as it seems: slice() returns
      # a string pointing inside the original string's allocated space.
      return source.slice(0, offs).count("\n") + 1
    end

    # Returns a list of all the C functions that are callable from Ruby.
    def cfunctions
      @cfunction ||= begin
        list = {}
        source.scan( /\n (?:static\s+)? VALUE\s+ (\w+) \( /x ) do |func, |
          list[func] = offs_to_line($~.begin(1))
        end
        list
      end
    end

    # Returns the fully-qualified Ruby class/module name behind a C variable.
    #
    #   Examples:
    #     "rb_mKernel" -> "Kernel"
    #     "cResolver" -> "YAML::Syck::Resolver"
    def c2r(cvar)
      return @c2r_cache[cvar] if @c2r_cache[cvar]
      @c2r_cache[cvar] = _c2r(cvar)
    end

    def _c2r(cvar)
      if source =~ /#{cvar} \s* = \s* rb_define_(?:class|module) \( \s* "([^"]+)" /x
        return $1
      end
      if source =~ /#{cvar} \s* = \s* rb_define_(?:class|module)_under \( \s* (\w+) \s* , \s* "([^"]+)" /x
        return c2r($1) + '::' + $2
      end
      if source =~ /#{cvar} \s* = \s* rb_path2class \( \s* "([^"]+)" /x
        return $1
      end
      # As a last resort we use C naming conventions:
      if cvar =~ /rb_[cm](.*)/
        return $1
      end
      raise NmNtFnd
    end

    # Returns a list of all the method definitions.
    def refs
      list = []
      source.scan( / (rb_define_method|rb_define_private_method|rb_define_singleton_method|rb_define_module_function)
                       \(
                          \s* (\w+) \s* ,
                          \s* "([^"]+)" \s* ,                                          #  "
                          \s* (\w+) /x ) do |definer, cvar, rfunc, cfunc |
        begin
          klass = c2r(cvar)
          is_singleton = (definer == 'rb_define_singleton_method' or definer == 'rb_define_module_function')
          is_instance  = (definer != 'rb_define_singleton_method')
          if is_singleton
            list << [klass + '--singleton', rfunc, cfunc]
          end
          if is_instance
            list << [klass, rfunc, cfunc]
          end
        rescue NmNtFnd
          puts "Couldn't find '#{cvar}'"
        end
      end

      list
    end
  end

end

