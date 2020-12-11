#
#  Be sure to run `pod spec lint HBHybridCollectionView.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name          = "HBHybridCollectionView"
  s.version       = "1.0.6"
  s.summary       = "Hybrid scroll collection view."
  s.homepage      = "https://github.com/Ban-Tang/HBHybridCollectionView"
  s.author        = { "Roylee" => "roylee.stillway@gmail.com" }
  s.description   = <<-DESC
                    A collection for hybrid scrolling, you can use a swipe list in a collection footer.
                    DESC

  s.platform      = :ios, "8.0"
  s.requires_arc  = true

  s.license       = { :type => "MIT", :file => "LICENSE" }

  s.source        = { :git => "https://github.com/Ban-Tang/HBHybridCollectionView.git", :tag => "#{s.version}" }
  s.source_files  = "hybrid/Hybrid/**/*.{h,m}"
  s.private_header_files = [
    "hybrid/Hybrid/HybridCollectionViewObserver.h",
    "hybrid/Hybrid/HybridCollectionViewProxy.h",
  ]

end
