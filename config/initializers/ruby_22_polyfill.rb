# Polyfill from Rubinius for Ruby 2.2's `slice_when` method
# https://github.com/rubinius/rubinius/commit/f21d58d735383a30156575a2c51b0982b6bae217
module Enumerable
  unless instance_methods.include? :slice_when
    def slice_when(&block)
      raise ArgumentError, "wrong number of arguments (0 for 1)" unless block_given?

      return [self] if one?

      Enumerator.new do |enum|
        ary = nil
        last_after = nil
        each_cons(2) do |before, after|
          last_after = after
          match = block.call before, after

          ary ||= []
          if match
            ary << before
            enum.yield ary
            ary = []
          else
            ary << before
          end
        end

        unless ary.nil?
          ary << last_after
          enum.yield ary
        end

      end
    end
  end
end
