require 'rubygems'
require 'cgi'
require 'logger'
require 'net/http'

#require 'xmlsimple'

module Vantage

  module ActionSDK

    class SOAP



    end

    class Rest

      DEFAULT_SERVER_ADDRESS = 'localhost'
      DEFAULT_SERVER_PORT = '8676'
      DEFAULT_BASE_PATH = '/FlipRest/'

      attr_accessor :logger, :server_address, :server_port, :http

      attr_reader :base_path

      # @param [Hash] args
      # @option args [String] :server_address
      # @option args [String] :server_port
      # @option args [String] :base_path (DEFAULT_BASE_PATH)
      def initialize(args = { })
        initialize_logger(args)
        @server_address = args[:server_address] || DEFAULT_SERVER_ADDRESS
        @server_port = args[:server_port] || DEFAULT_SERVER_PORT

        @http = Net::HTTP.new(server_address, server_port)

        self.base_path = args[:base_path] ||= DEFAULT_BASE_PATH
      end

      def initialize_logger(args = { })
        @logger = args[:logger] ||= Logger.new(STDERR)
      end

      def base_path=(value)
        @base_path = value
        return unless @base_path.is_a?(String)
        @base_path = base_path.insert(0, '/') unless @base_path.start_with?('/')
        @base_path += '/' unless base_path.end_with?('/')
      end


      def do_get(path, options = { })
        query = options[:query] || { }
        headers = options[:headers] || { }
        headers['accepts'] ||= 'text/xml'

        query_as_string = query.map { |k,v| "#{k}=#{v}" }.join('&')
        _path = "#{base_path}#{path}?#{query_as_string}"
        logger.debug { "GET #{_path}" }
        response = http.get(_path, headers)
        response.body
      end

      def query_hash_to_string(hash)
        return hash unless hash.is_a?(Hash)
        hash.map { |k,v| "#{k}=#{v}" }.join('&')
      end

      def do_post_xml(path, data, options = { })
        headers = options[:headers] || { }
        headers['accepts'] ||= 'text/xml'
        headers['content-type'] ||= 'text/xml'

        _path = "#{base_path}#{path}"
        query = options[:query]
        if query
          query_as_string = query_hash_to_string(query)
          _path += "?#{query_as_string}"
        end
        #puts "DATA:\n#{data}"
        response = http.post(_path, data, headers)
        response.body
      end

      def do_post(path, data, options = { })
        headers = options[:headers] || { }
        headers['accepts'] ||= 'text/xml'

        _path = "#{base_path}#{path}"
        query = options[:query]
        if query
          query_as_string = query_hash_to_string(query)
          _path += "?#{query_as_string}"
        end
        response = http.post(_path, data, headers)
        response.body
      end

      def build_xml_element(hash)
        hash.map { |k,v| %(<#{k}#{v.nil? ? ' i:nil="true"/>' : ">#{v.is_a?(Hash) ? add_xml_element(v) : v}</#{k}>"}) }.join
      end

      def build_xml(hash)
        hash.map { |k, v| %(<#{k} xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://Telestream.Vantage.Sdk/2010/07">#{build_xml_element(v)}</#{k}>) }.join
      end

      # @!group API METHODS

      def get_version
        do_get('ActionGetVersion')
      end

      # Submit a new transcode job to Vantage using the Action SDK.
      #
      # @param [Hash] args
      # @option args [String] :source_file_path The source media file that will be transcoded (flipped).
      # @option args [String] :output_location The output location where the transcoder should create the new file.
      # @option args [String] :output_name The basename (everything but the last extension) of the output file (eg: if
      #   you are using the quicktime movie encoder and you specify a basename of 'file1234'; the final output filename
      #   would be:  'file1234.mov'
      # @option args [String] :definition The encoder definition that is to be applied during this job.  This is
      #   obtained using the 'export' option from the context menu of the Flip action in the Vantage workflow designer.
      # @option args [String] :prefix The job prefix.  This corresponds to an optional text string that will be
      #   prepended to the job name during a submit.  Pass nil if a prefix is not desired.
      # @option args [Integer] :priority (0) The priority that the new job should be submitted with.  A value of 0
      #   implies no specified priority. The higher the value, the more important the job is.
      # @return [String] The GUID value which corresponds to the identifier for the job.
      def flip(args = { })
        source_file_path = args[:source_file_path]
        output_location = args[:output_location]
        output_name = args[:output_name]
        definition = args[:definition] || begin
          definition_file_path = args[:definition_file_path]
          raise ArgumentError, ':definition or :definition_file_path is a required argument.' unless definition_file_path
          xml = File.read(definition_file_path)
          xml
        end

        definition = CGI.escapeHTML(definition) if definition.start_with?('<')

        prefix = args[:prefix]
        priority = args[:priority] ||= 0

        data = {
          # Definition has to come before 'OutputLocation', 'OutputName', and 'SourceFilePath' or the submission fails
          'Definition' => definition,

          'Prefix' => prefix,
          'Priority' => priority,
          # 'Variables' => nil,
          # 'Decoder' => nil,
          'OutputLocation' => output_location,
          'OutputName' => output_name,
          'SourceFilePath' => source_file_path,
        }

        xml = build_xml('FlipSubmitMessage' => data)

        do_post_xml('Flip', xml)
      end

      # Request that the job with the specified identifier be stopped.
      #
      # @param [Hash] args
      # @option args [String] :identifier The identifier of the job to restart.
      # @return [Boolean]
      def job_stop(args = { })
        identifier = args[:identifier]
        query = { 'identifier' => identifier }
        do_post('StopJob', { }, :query => query)
      end

      # Perform a restart on a job which had previously been stopped.  Only jobs which have been previously stopped (or
      # which have failed) are candidates for restarting.  Attempting to restart a job which is in progress shall
      # result in an error.
      #
      # @param [Hash] args
      # @option args [String] :identifier The identifier of the job to restart.
      # @return [Boolean]
      def job_restart(args = { })
        identifier = args[:identifier]
        query = { 'identifier' => identifier }
        do_post('RestartJob', { }, :query => query)
      end

      # Attempt to delete a job.  Only jobs which are completed (either completed successfully, completed with a
      # failure, or jobs which have been stopped) may be deleted.  Attempting to delete a running job will result in an
      # error.
      #
      # @param [Hash] args
      # @option args [String] :identifier
      # @return [Boolean]
      def job_remove(args = { })
        identifier = args[:identifier]
        query = { 'identifier' => identifier }
        do_post('RemoveJob', { }, :query => query)
      end

      # Request that a job run with a new priority.  A higher priority will result in the job being made more important
      # (possibly allowing it to pre-empt other jobs).  A lower priority may allow the job to be pre-empted by a higher
      # priority job.
      #
      # @param [Hash] args
      # @option args [String] :identifier The identifier of the job to change the priority of.
      # @option args [Integer] :new_priority The new priority (should be >= 0)
      def job_change_priority(args = { })
        identifier = args[:identifier]
        new_priority = args[:new_priority]
        query = { 'identifier' => identifier, 'newPriority' => new_priority }
        do_post('SetJobPriority', { }, :query => query)
      end

      # Obtain the current state of the job.
      #
      # @param [Hash] args
      # @option args [String] :identifier The identifier of the job to get the state of.
      # @return [String]
      def job_state(args = { })
        identifier = args[:identifier]
        query = { 'identifier' => identifier }
        do_get('ActionGetJobState', :query => query)
      end

      # Obtain the progress for the specified job.  The progress shall be returned as a value between [0..100].
      #
      # NOTE:  If the job is completed (either having successfully completed or failed); the progress shall be returned
      # with a value of 100.
      #
      # @param [Hash] args
      # @option args [String] :identifier The identifier of the job to get the progress of.
      # @return [Integer]
      def job_progress(args = { })
        identifier = args[:identifier]
        query = { 'identifier' => identifier }
        do_get('ActionGetJobProgress', :query => query)
      end

      # Attempt to pause the specified job.  Not all jobs may be paused and certain criteria may prevent a job from
      # being paused (eg: too many previously paused jobs).  If a job can not be paused; an error shall be returned.
      #
      # @param [Hash] args
      # @option args [String] :identifier The identifier of the job to pause.
      # @return [Boolean]
      def job_pause(args = { })
        identifier = args[:identifier]
        query = { 'identifier' => identifier }
        do_post('Pause', { }, :query => query)
      end


      # Attempt to resume a job which had previously been paused.  Attempting to resume a job which is in any state but
      # 'Paused' will result in an error.
      #
      # @param [Hash] args
      # @option args [String] :identifier The identifier of the job to resume.
      # @return [Boolean]
      def job_resume(args = { })
        identifier = args[:identifier]
        query = { 'identifier' => identifier }
        do_post('Resume', { }, :query => query)
      end

      # @!endgroup

    end

  end

end