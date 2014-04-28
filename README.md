# Vantage

## Utilities

### vantage_flip [bin/vantage_flip]

#### Description
  A utility to submit a new transcode (flip) job to Vantage using the Action SDK Flip action

#### Usage
    Usage: vantage_flip [options]
            --server-address ADDRESS     The address of the Vantage server.
            --server-port PORT           The port that the Vantage server is listening on.
            --source-file-path PATH      The source media file that will be transcoded (flipped).
                                         NOTE: This path needs to be relative to the server.
            --output-location PATH       The output location where the transcoder should create the new file.
                                         NOTE: This path needs to be relative to the server.
            --output-name NAME           The basename (everything but the last extension) of the output file.
                                         (eg: if you are using the quicktime movie encoder and you specify a basename of 'file1234'; the final output filename would be:  'file1234.mov'
            --definition-file PATH       The path to the xml file containing the flip definition.
        -h, --help                       Displays this message.

#### Example
    ./vantage_flip --server-address localhost --source-file-path "M:\Vantage_Test\sd_in\xplatform.mov" --output-location "m:\Vantage_Test\sd_out" --output-name testfile_out --definition-file dev/flip_definition.xml

#### Options File

##### Default Options File Location
    ~/.options/vantage_flip

##### Options File Content Example
    --server-address=127.0.0.1
    --definition-file=/flip_definitions/default_flip_definition.xml

### vantage_transcode [bin/vantage_transcode]

#### Description
  A utility to submit a new transcode job to Vantage

#### Usage
    Usage: vantage_transcode [options]
            --server-address ADDRESS     The address of the Vantage server.
            --server-port PORT           The port that the Vantage server is listening on.
            --source-file-path PATH      The source media file that will be transcoded (flipped).
                                         NOTE: This path needs to be relative to the server.
            --output-location PATH       The output location where the transcoder should create the new file.
                                         NOTE: This path needs to be relative to the server.
            --output-name NAME           The basename (everything but the last extension) of the output file.
                                         (eg: if you are using the quicktime movie encoder and you specify a basename of 'file1234'; the final output filename would be:  'file1234.mov'
            --definition-file PATH       The path to the xml file containing the flip definition.
        -h, --help                       Displays this message.

#### Options File

##### Default Options File Location
    ~/.options/vantage_transcode

##### Options File Content Example
    --server-address=127.0.0.1
    --definition-file=/flip_definitions/default_flip_definition.xml

### vantage_submit_file [bin/vantage_submit_file]

#### Description
  A utility to submit files to a Vantage workflow using the submitFile action.

#### Usage

    Usage: vantage_submit_file [options] [file_or_directory_path, file_or_directory_path, ...]
            --server-address ADDRESS     The address of the Vantage server.
            --server-port PORT           The port that the Vantage server is listening on.
            --workflow-identifier ID     The id of the workflow to submit the file to.
            --source-file-path FILENAME  The path of the file to submit.
            --job-name NAME              A name to give to the job when it is submitted.
            --context CONTEXT            A JSON string representing the context argument to be passed to the workflow.
            --path-substitutions JSON    A JSON String containing path substitutions in the form of key value pairs for find => replace

#### Examples

##### Submit File(s) to Vantage Workflow using Vantage SOAP SDK
    ./vantage_submit_file --server-address localhost --workflow-identifier 9646d57c-cd42-44bf-80df-d3ea34d73a4a --job-name "Some Job Name" --source-file-path "M:\\Vantage_Test\\sd_in\\xplatform.mov" /Volumes/Xsan/*

##### Submit File(s) to Vantage Workflow using Vantage SOAP SDK and using path substitutions to convert unix paths to Windows drive paths
    ./vantage_submit_file --server-address 10.1.3.76 --workflow-identifier 9646d57c-cd42-44bf-80df-d3ea34d73a4a --job-name "Some Job Name" /Volumes/Xsan/* --path-substitutions '{"/Volumes":"C:\\"}'


## Contributing

1. Fork it ( http://github.com/XPlatform-Consulting/vantage/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
