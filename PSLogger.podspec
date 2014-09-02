Pod::Spec.new do |spec|
  spec.name          = "PSLogger"
  spec.version       = "0.0.1"
  spec.summary       = "Logging system for Peaches Studio Product."
  spec.homepage      = "https://github.com/PeachesStudio/PSLog/"
  spec.license       = 'MIT'
  spec.author        = { "liuqin.sheng" => "sliuqin@gmail.com" }
  spec.source        = { :git => "https://github.com/PeachesStudio/PSLogger.git", :tag => spec.version.to_s }
  spec.platform      = :ios, '7.0'
  spec.source_files  = 'Classes/PSLogger.{h,m}'
  spec.requires_arc  = true
  spec.dependency 'CocoaLumberjack'
end