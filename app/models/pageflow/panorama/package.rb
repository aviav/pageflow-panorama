require 'zip'

module Pageflow
  module Panorama
    class Package < ActiveRecord::Base
      include HostedFile

      processing_state_machine do
        state 'unpacking'
        state 'unpacked'
        state 'unpacking_failed'

        event :process do
          transition any => 'unpacking'
        end

        event :retry do
          transition 'unpacking_failed' => 'unpacking'
        end

        job UnpackPackageJob do
          on_enter 'unpacking'
          result :ok, state: 'unpacked'
          result :error, state: 'unpacking_failed'
        end
      end

      has_attached_file(:thumbnail, Pageflow.config.paperclip_s3_default_options
                          .merge(default_url: ':pageflow_placeholder',
                                 default_style: :thumbnail,
                                 styles: {
                                   :thumbnail  => ["100x100#", :JPG],
                                   :navigation_thumbnail_small => ['85x47#', :JPG],
                                   :navigation_thumbnail_large => ['170x95#', :JPG],
                                   :thumbnail_overview_desktop => ['230x72#', :JPG],
                                   :thumbnail_overview_mobile => ['200x112#', :JPG]
                                 }))

      # @override
      def keep_on_filesystem_after_upload_to_s3?
        true
      end

      def unpack_base_path
        attachment_on_s3.present? ? File.dirname(attachment_on_s3.path(:unpacked)) : nil
      end

      def index_document_path
        if attachment_on_s3.present? && index_document
          File.join(Panorama.config.packages_base_path, unpack_base_path, index_document)
        end
      end

      def archive
        @archive ||= Zip::File.open(attachment_on_filesystem.path)
      end

      def unpacker
        UnpackToS3.new(archive: archive,
                       destination_bucket: attachment_on_s3.s3_bucket,
                       destination_base_path: unpack_base_path)
      end
    end
  end
end