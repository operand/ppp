# frozen_string_literal: true

module PPP
  module InstanceMethods
    # Pretty print object and contextual info
    def ppp(object = :none_provided)
      caller_binding = binding.of_caller(2)
      current_binding = binding.of_caller(1)

      output = ''
      output += ('—' * 80).yellow
      output += "\n"
      output += "#{ 'location:'.blue } #{binding_name(current_binding)}\n"
      output += "#{ 'caller:'.blue }   #{binding_name(caller_binding)}\n"

      if (object == :none_provided) && (current_method_name = current_binding.eval('__method__'))
        # print current method argument values
        the_method = current_binding.eval("self.method(:#{current_method_name})")
        parameters = the_method.parameters.map do |arg|
          ai_inspect(current_binding.eval(arg[1].to_s))
        end
        output += "#{ 'args:'.blue }     (#{parameters.join(', ')})\n"
      end

      if (contents = binding_contents(current_binding))
        output += "\n#{contents}\n"
      end

      output += "\n=>  #{object_output(object)}\n" unless object == :none_provided
      output += ('—' * 80).yellow

      puts output
    rescue StandardError
      if $ERROR_INFO
        puts "An error occurred while inspecting object #{$ERROR_INFO.class.name} #{$ERROR_INFO.message}"
        puts $ERROR_INFO.backtrace[0..4].join("\n\t")
      end
      raise
    ensure
      return object unless object == :none_provided
    end

    def binding_name(ppp_binding)
      line = binding_line(ppp_binding)
      file = binding_file(ppp_binding).gsub("#{pwd}/", '')
      context = binding_context(ppp_binding)

      "#{context.ai}  #{file}:#{line}"
    end

    def binding_file(ppp_binding)
      if ppp_binding.respond_to? :source_location
        ppp_binding.source_location[0]
      else
        ppp_binding.eval("__FILE__")
      end
    end

    def binding_line(ppp_binding)
      if ppp_binding.respond_to? :source_location
        ppp_binding.source_location[1]
      else
        ppp_binding.eval('__LINE__')
      end
    end

    def binding_contents(ppp_binding)
      file = binding_file(ppp_binding)
      line = binding_line(ppp_binding)
      lines = File.open(file).to_a

      <<~LINES.strip
        #{format_line(lines, line - 3)}
        #{format_line(lines, line - 2)}
        #{format_line(lines, line - 1, main: true)}
        #{format_line(lines, line - 0)}
        #{format_line(lines, line + 1)}
      LINES
    rescue Errno::ENOENT # No such file or directory
      nil
    end

    def binding_context(ppp_binding)
      if (method_name = ppp_binding.eval('__method__'))
        ppp_binding.eval("self.method(:\"#{method_name}\")")
      else
        ppp_binding.eval('self.class')
      end
    end

    def format_line(lines, line_number, main: false)
      return unless (contents = lines[line_number])

      if main
        "#{line_number} > #{contents.gsub(/\s*$/, '').gsub('ppp', 'ppp'.green)}"
      else
        "#{line_number.to_s.gray}   #{contents.gsub(/\s*$/, '').gray}"
      end
    end

    def pwd
      `pwd`.strip
    end

    def object_output(object)
      object.respond_to?(:ai) ? object.ai : object.inspect
    end

    def ai_inspect(object)
      ai_options = {
        indent: 2,
        index: false,
        object_id: false,
      }

      plain_inspected = object.ai(ai_options.merge(plain: true))

      if plain_inspected.length > 40
        object.ai(
          ai_options.merge(
            limit: 2,
            multiline: false,
            raw: false,
          ),
        )
      else
        object.ai(ai_options)
      end
    end
  end
end

class Object
  include PPP::InstanceMethods
end
