require 'fastlane/action'
require_relative '../helper/aliyunoss_helper'
require 'aliyun/oss'

module Fastlane
  module Actions
    class AliyunossAction < Action
      def self.run(params)
        UI.message("The aliyunoss plugin is working!")
        
        endpoint = params[:endpoint]
        access_key_id = params[:access_key_id]
        access_key_secret = params[:access_key_secret]
        bucket_name = params[:bucket_name]
        bucket_dir_path = params[:bucket_dir_path]

        ipa = params[:ipa]
        archive = params[:archive]
        dsym = params[:dsym]

        now = Time.now.strftime("%Y%m%d/%H%M%S")

        backup_archive = "#{File.expand_path(File.dirname(ipa))}/#{File.basename(ipa, ".*")}.xcarchive.zip"
        UI.message "compress xcarchive"
        Actions.sh(%(zip -r -X -y -q "#{backup_archive}" "#{File.expand_path(archive)}"))

        client = Aliyun::OSS::Client.new(
          endpoint: endpoint,
          access_key_id: access_key_id,
          access_key_secret: access_key_secret)
        bucket = client.get_bucket(bucket_name)

        UI.message "upload ipa: #{ipa}"
        bucket.put_object("#{bucket_dir_path}/#{now}/#{File.basename(ipa)}", :file => "#{ipa}")
        UI.message "upload ipa done"

        UI.message "upload archive: #{backup_archive}"
        bucket.put_object("#{bucket_dir_path}/#{now}/#{File.basename(backup_archive)}", :file => "#{backup_archive}")
        UI.message "upload archive done"

        UI.message "upload dsym: #{dsym}"
        bucket.put_object("#{bucket_dir_path}/#{now}/#{File.basename(dsym)}", :file => "#{dsym}")
        UI.message "upload dsym done"

        UI.message("The aliyunoss plugin done")
      end

      def self.description
        "upload package to aliyunoss"
      end

      def self.authors
        ["yigua"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        ""
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :endpoint,
            env_name: "endpoint",
            description: "",
            optional: false),
          FastlaneCore::ConfigItem.new(key: :access_key_id,
            env_name: "access_key_id",
            description: "",
            optional: false),
          FastlaneCore::ConfigItem.new(key: :access_key_secret,
            env_name: "access_key_secret",
            description: "",
            optional: false),
          FastlaneCore::ConfigItem.new(key: :bucket_name,
            env_name: "bucket_name",
            description: "",
            optional: false),
          FastlaneCore::ConfigItem.new(key: :bucket_dir_path,
            env_name: "bucket_dir_path",
            description: "Storage directory for files",
            optional: false),
          FastlaneCore::ConfigItem.new(key: :ipa,
            env_name: "ipa",
            description: "Path to your ipa",
            default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
            optional: true,
            verify_block: proc do |value|
              UI.user_error!("Couldn't find ipa file at path '#{value}'") unless File.exist?(value)
            end),
          FastlaneCore::ConfigItem.new(key: :archive,
            env_name: "archive",
            description: "Path to your archive",
            default_value: Actions.lane_context[SharedValues::XCODEBUILD_ARCHIVE],
            optional: true,
            verify_block: proc do |value|
              UI.user_error!("Couldn't find archive file at path '#{value}'") unless File.exist?(value)
            end),
          FastlaneCore::ConfigItem.new(key: :dsym,
            env_name: "dsym",
            description: "Path to your dsym",
            default_value: Actions.lane_context[SharedValues::DSYM_OUTPUT_PATH],
            optional: true,
            verify_block: proc do |value|
              UI.user_error!("Couldn't find dsym file at path '#{value}'") unless File.exist?(value)
            end)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        [:ios].include?(platform)
        true
      end
    end
  end
end
