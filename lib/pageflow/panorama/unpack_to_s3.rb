require 'zip'

module Pageflow
  module Panorama
    class UnpackToS3
      attr_reader :archive, :destination_bucket, :destination_base_path, :content_type_mapping

      def initialize(archive:, destination_bucket:, destination_base_path:, content_type_mapping: {})
        @archive = archive
        @destination_bucket = destination_bucket
        @destination_base_path = destination_base_path
        @content_type_mapping = content_type_mapping
      end

      def upload
        archive.entries.each_with_index do |entry, index|
          yield(100.0 * index / archive.entries.size) if block_given?
          upload_entry(entry)
        end

        yield(100) if block_given?
      end

      private

      def upload_entry(entry)
        return unless entry.file?
        with_retry do
          destination_bucket.write(name: destination_path(entry.name),
                                   input_stream: entry.get_input_stream,
                                   content_length: entry.size,
                                   content_type: content_type_for(entry.name))
        end
      end

      def destination_path(file_name)
        File.join(destination_base_path, file_name)
      end

      def content_type_for(file_name)
        content_type_mapping[File.extname(file_name).delete('.')]
      end

      def with_retry
        retries = 0

        begin
          yield
        rescue AWS::S3::Errors::SlowDown
          retries += 1

          raise if retries > 5

          sleep((2**retries) * 0.5)
          retry
        end
      end
    end
  end
end
