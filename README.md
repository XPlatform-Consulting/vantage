# Vantage

## Utilities

### vantage_flip [bin/vantage_flip]

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

#### Example
    ./vantage_transcode --server-address localhost --source-file-path "M:\Vantage_Test\sd_in\xplatform.mov" --output-location "m:\Vantage_Test\sd_out" --output-name testfile_out --definition-file dev/flip_definition.xml

#### Options File

##### Default Options File Location
    ~/.options/vantage_transcode

##### Options File Content Example
    --server-address=127.0.0.1
    --definition-file=/flip_definitions/default_flip_definition.xml

## Contributing

1. Fork it ( http://github.com/XPlatform-Consulting/vantage/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
