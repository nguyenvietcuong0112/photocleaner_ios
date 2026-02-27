Pod::Spec.new do |s|
  s.name             = 'ffmpeg-kit-ios-full'
  s.version          = '6.0.LTS'
  s.summary          = 'FFmpegKit full package for iOS (community-hosted)'
  s.description      = 'Prebuilt FFmpegKit xcframeworks for iOS. Community mirror since original was retired Jan 2025.'
  s.homepage         = 'https://github.com/arthenica/ffmpeg-kit'
  s.license          = { :type => 'LGPL-3.0' }
  s.author           = { 'ARTHENICA' => 'open-source@arthenica.com' }

  s.platform         = :ios, '10.0'
  s.static_framework = true

  s.source = {
    :http => 'https://github.com/luthviar/ffmpeg-kit-ios-full/releases/download/6.0/ffmpeg-kit-ios-full.zip'
  }

  s.vendored_frameworks = 'ffmpeg-kit-ios-full/*.xcframework'
end
