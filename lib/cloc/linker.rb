
module Cloc

  # Connects method declarations to location of c functions.
  # The result is written to the database.
  class Linker

    def initialize
      @table = {}
      @non_static_functions = {}
    end

    def process_file(pathname)
      puts "Processing #{pathname} ...\n#"
      src = FileSource.new(pathname)
      src.refs.each do |klass, rmethod, cfunc|
        if @table[klass]
          klass = @table[klass]
        else
          klass = @table[klass] = {}
        end
        klass[rmethod] = begin
          if src.cfunctions[cfunc]
            # Resolve static methods.
            [ File.expand_path(pathname), src.cfunctions[cfunc] ]
          else
            # Postpone to later.
            cfunc
          end
        end
      end

      # Save non-static functions for later.
      src.cfunctions.each_pair do |cfunc, lineno|
        @non_static_functions[cfunc] = [ File.expand_path(pathname), lineno ]
      end
    end

    def resolve_non_static_functions
      @table.each_pair do |klass, methods_table|
        methods_table.each_pair do |method, location_or_cfunction|
          if location_or_cfunction.is_a? String
            if @non_static_functions[location_or_cfunction]
              methods_table[method] = @non_static_functions[location_or_cfunction]
            end
          end
        end
      end
    end

    def remove_missing
      @table.each_pair do |klass, methods_table|
        methods_table.each_pair do |method, location_or_cfunction|
          if location_or_cfunction.is_a? String
            puts "Couldn't resolve #{klass}##{method}"
            methods_table.delete(method)
          end
        end
      end
    end

    def data
      @table
    end

  end

end
