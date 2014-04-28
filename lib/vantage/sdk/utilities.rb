require 'logger'
require 'net/http'

module Vantage

  class SDK

    class Utilities

      DEFAULT_SERVER_ADDRESS = 'localhost'
      DEFAULT_SERVER_PORT = 8676

      attr_accessor :logger, :http, :path_substitutions

      def initialize(args = { })
        initialize_logger(args)
        @server_address = args[:server_address] || DEFAULT_SERVER_ADDRESS
        @server_port = args[:server_port] || DEFAULT_SERVER_PORT

        @path_substitutions = args[:path_substitutions] || { }

        @http = Net::HTTP.new(@server_address, @server_port)
      end

      def initialize_logger(args = { })
        @logger = args[:logger] ||= Logger.new(STDERR)
      end

      def substitute_paths(file_path, _path_substitutions = path_substitutions, options = { })
        return file_path.map { |fp| substitute_paths(fp, _path_substitutions, options) } if file_path.is_a?(Array)
        _path_substitutions.each do |from, to|
          if file_path.include?(from)
            new_file_path = file_path.sub(from, to)
            logger.debug { "Translating path '#{file_path}' => '#{new_file_path}'"}
            return new_file_path
          end
        end
        file_path
      end


      def post_xml_net_http(path, action, xml, options = { })
        _path = "/#{path}"

        headers = options[:headers] || { }
        headers['Content-Type'] = 'text/xml;charset=UTF-8'
        headers['SOAPAction'] = action

        logger.debug { "POST #{path}\nHEADERS\n#{PP.pp(headers, '')}\nBODY\n#{xml}" }

        #request = Net::HTTP::Post.new(_path, headers)
        response = http.post(_path, xml, headers)
        response.body
      end

      def post_xml(path, action, data, options = { })
        post_xml_net_http(path, action, data, options)
      end

      def snake_case_to_lower_camel_case(string)
        string.to_s.split('_').inject([]){ |buffer,e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
      end

      def normalize_key(key, options = { })
        return key unless key.respond_to?(:to_s)
        snake_case_to_lower_camel_case(key)
      end

      def normalize_keys_to_lower_camel_case(hash, options = { })
        recursive = options[:recusive]
        Hash[ hash.map { |k,v| [ normalize_key(k), ( ( recursive and v.is_a?(Hash) ) ? normalize_keys_to_lower_camel_case(v) : v )  ] } ]
      end

      # @param [Symbol|String] parameter_name A symbol or string in snake case form
      def normalize_arguments(arguments, options = { })
        recursive = options.fetch(:recursive, options[:normalize_arguments_recursively])
        if recursive
          arguments = Hash[arguments.dup.map { |k,v| [ ( k.respond_to?(:to_s) ? k.to_s.gsub('_', '').downcase : k ),  ( v.is_a?(Hash) ? normalize_arguments(v, options) : v ) ] } ]
        else
          arguments = Hash[arguments.dup.map { |k,v| [ ( k.respond_to?(:to_s) ? k.to_s.gsub('_', '').downcase : k ) , v ] } ]
        end
        arguments
      end

      def filter_arguments(arguments, parameter_names, options = { })
        parameter_names_normalized = parameter_names.is_a?(Hash) ? parameter_names : Hash[[*parameter_names].map { |param_name| [ param_name.to_s.gsub('_', '').downcase, param_name ] } ]
        arguments_normalized = normalize_arguments(arguments, options)
        logger.debug { "Normalized Arguments: #{PP.pp(arguments_normalized, '')}"}
        filtered_arguments = {}

        arguments_normalized.dup.each do |k,v|
          param_name = parameter_names_normalized.delete(k)
          logger.debug { "Parameter '#{k}' Not Found" } and next unless param_name
          logger.debug { "Setting Parameter '#{param_name}' => #{v.inspect}" }
          filtered_arguments[param_name] = v
          break if parameter_names_normalized.empty?
        end

        return filtered_arguments
      end

      def process_parameters(parameters, arguments, options = { })
        defaults = { }
        parameter_names = [ ]
        required_parameters = { }

        [*parameters].each do |param|
          if param.is_a?(Hash)
            parameter_name = param[:name]
            defaults[parameter_name] = param[:default_value] if param.has_key?(:default_value)
            required_parameters[parameter_name] = param if param[:required]
          else
            parameter_name = param
          end
          parameter_names << parameter_name
        end

        logger.debug { "Processing Parameter(s): #{parameter_names.inspect}" }
        arguments_out = defaults.merge(filter_arguments(arguments, parameter_names, options))
        missing_required_parameters = required_parameters.keys - arguments_out.keys
        raise ArgumentError, "Missing Required Parameter(s): #{missing_required_parameters.join(', ')}" unless missing_required_parameters.empty?
        return arguments_out
      end

      def build_ns_elements(hash)
        hash.map { |k,v| new_key = snake_case_to_lower_camel_case(k); "<ns:#{new_key}>#{v}</ns:#{new_key}>" }
      end

      def submit_file(args = { })
        parameters = [ :workflow_identifier, :source_filename, :context, :job_name ]
        _args = process_parameters(parameters, args)

        source_filename = _args[:source_filename].dup
        source_filename = substitute_paths(source_filename) if source_filename
        #source_filename.gsub!('\\', '/')
        _args[:source_filename] = source_filename

        # Enforce the order of the arguments
        elements = parameters.map { |k| build_ns_elements( k => _args[k] ).pop if _args.has_key?(k) }.compact

        xml = <<-XML
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://Telestream.Vantage.Sdk/2010/07" xmlns:tel="http://schemas.datacontract.org/2004/07/Telestream.Soa.Vocabulary" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:SubmitFile>
        #{elements.join("\n\t")}
      </ns:SubmitFile>
   </soapenv:Body>
</soapenv:Envelope>
        XML
        post_xml('Submit', 'http://Telestream.Vantage.Sdk/2010/07/IWorkflowSubmit/SubmitFile', xml)
      end

      def submit_file_and_items(args = { })
        # http://Telestream.Vantage.Sdk/2010/07/IWorkflowSubmit/SubmitFileAndItems
      end

      def submit_items(args = { })
        # http://Telestream.Vantage.Sdk/2010/07/IWorkflowSubmit/SubmitItems
      end

    end

  end

end