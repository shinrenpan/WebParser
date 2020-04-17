Pod::Spec.new do |spec|

  spec.name          = "WebParser"
  spec.version       = "4.1.0"
  spec.summary       = "Web crawler for iOS"

  spec.description   = <<-DESC
                       基於 WKWebView 的 iOS 爬蟲, 簡單使用 JavaScript 就可以爬遍網站
                       DESC

  spec.homepage      = "https://github.com/shinrenpan/WebParser"
  spec.license       = { :type => "MIT", :file => "LICENSE" }
  spec.author        = { "Shinren Pan" => "shinren.pan@gmail.com" }
  spec.platform      = :ios, "9.0"
  spec.swift_version = "5.2"
  spec.source        = { :git => "https://github.com/shinrenpan/WebParser.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/*.{swift}"
  spec.frameworks    = "UIKit", "WebKit"

end
