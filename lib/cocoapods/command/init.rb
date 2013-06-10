require 'xcodeproj'
require 'active_support/core_ext/string/strip'

module Pod
  class Command
    class Init < Command

      self.summary = 'Generate a Podfile for the current directory.'
      self.description = <<-DESC
        Creates a Podfile for the current directory if none currently exists. If
        an Xcode project file is specified or if there is only a single project
        file in the current directory, targets will be automatically generated
        based on targets defined in the project.
      DESC
      self.arguments = '[XCODEPROJ]'

      def initialize(argv)
        @podfile_path = Pathname.pwd + "Podfile"
        @project_path = argv.shift_argument
        @project_paths = Pathname.pwd.children.select { |pn| pn.extname == '.xcodeproj' }
        super
      end

      def validate!
        super
        help! "Existing Podfile found in directory" unless config.podfile.nil?
        unless @project_path
          help! "No xcode project found, please specify one" unless @project_paths.length > 0
          help! "Multiple xcode projects found, please specify one" unless @project_paths.length == 1
          @project_path = @project_paths.first
        end
        help! "Xcode project at #{@project_path} does not exist" unless File.exist? @project_path
        @xcode_project = Xcodeproj::Project.new(@project_path)
      end

      def run
        @podfile_path.open('w') { |f| f << podfile_template(@xcode_project) }
      end

      private

      # @param  [Xcodeproj::Project] project
      #         The xcode project to generate a podfile for.
      #
      # @return [String] the text of the Podfile for the provided project
      #
      def podfile_template(project)
        podfile = <<-PLATFORM.strip_heredoc
          # Uncomment this line to define a global platform for your project
          # platform :ios, "6.0"
        PLATFORM
        for target in project.targets
          podfile << target_module(target, !has_global_platform)
        end
        podfile
      end

      # @param  [Xcodeproj::PBXTarget] target
      #         A target to generate a Podfile target module for.
      #
      # @return [String] the text for the target module
      #
      def target_module(target)
        return <<-TARGET.strip_heredoc

          target "#{target.name}" do

          end
        TARGET
      end
    end
  end
end
