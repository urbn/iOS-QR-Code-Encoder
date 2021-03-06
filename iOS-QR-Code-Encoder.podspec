Pod::Spec.new do |s|
  s.name         = "iOS-QR-Code-Encoder"
  s.version      = "0.0.4.2"
  s.summary      = "iOS QR encoder, generates an UIImage from NSString with one line of code. Uses libqrencode to encode a string into qr."
  s.homepage     = "http://cocoacontrols.com/platforms/ios/controls/ios-qr-encoder"
  s.license      = 'MIT'
  s.author       = { "Andrew Kopanev" => "andrew@moqod.com" }
  s.source       = { :git => "https://github.com/urbn/iOS-QR-Code-Encoder.git"}
  s.platform     = :ios
  s.source_files = 'Classes/QRCodeGenerator.{h,m}', 'libqrencode/*.{h,c}'
  s.public_header_files = 'Classes/QRCodeGenerator.h'
end