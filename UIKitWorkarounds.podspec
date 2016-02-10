Pod::Spec.new do |s|
  s.name             = "UIKitWorkarounds"
  s.version          = "0.2.0"
  s.summary          = "A modular collection of workarounds and fixes for our favorite iOS framework."

  s.description      = 'A detailed description will be here soon. Someday.'

  s.homepage         = "https://github.com/nickynick/UIKitWorkarounds"  
  s.license          = 'MIT'
  s.author           = { "Nick Tymchenko" => "t.nick.a@gmail.com" }
  s.source           = { :git => "https://github.com/nickynick/UIKitWorkarounds.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nickynick42'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'UIKitWorkarounds/**/*.{h,m}'
  s.public_header_files = 'UIKitWorkarounds/**/*.h'

  s.frameworks = 'UIKit'
end
