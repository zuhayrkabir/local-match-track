# WARNING - GENERATED FILE - DO NOT EDIT
# This file is generated from a template found in `<monorepo>/sdks/flutter/scripts/templates`

#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ditto_live.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name = 'ditto_live'
  s.version = "5.1.0"
  s.summary = 'A new Flutter FFI plugin project.'
  s.description = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage = 'https://www.ditto.com'
  s.license = { :file => '../LICENSE' }
  s.authors = "Ditto"

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.dependency 'FlutterMacOS'

  s.platforms = { :osx => "11.0" }
  s.static_framework = true

  s.dependency "DittoFlutter", "5.1.0"

  # uncomment the following line to use a local binary
  # s.vendored_frameworks = 'DittoCore.xcframework'
  s.source = {
    path: "."
  }

  # v5 Apple builds are arm64-only (x86_64/Intel dropped in SDKS-3740, #22785).
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=macosx*]' => 'x86_64' }
  s.swift_version = '5.0'
end
