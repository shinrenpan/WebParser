Pod::Spec.new do |spec|

  spec.name          = "WebParser"
  spec.version       = "4.1.0"
  spec.summary       = "Web crawler for iOS"

  spec.description   = <<-DESC
                       Web crawler for iOS
                       DESC

  spec.homepage      = "https://github.com/shinrenpan/WebParser"
  spec.license       = { :type => "MIT", :file => "LICENSE" }
  spec.author        = { "Shinren Pan" => "shinren.pan@gmail.com" }
  spec.platform      = :ios, "9.0"
  spec.swift_version = "5.2"
  spec.source        = { :git => "https://github.com/shinrenpan/WebParser", :tag => "#{spec.version}" }
  spec.source_files  = ["Sources/*.swift", "Sources/WebParser.h"]
  spec.exclude_files = ["Sources/**"]
  spec.frameworks    = "UIKit", "WebKit"

end
