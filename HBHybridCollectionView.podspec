#
#  Be sure to run `pod spec lint hybrid.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "HBHybridCollectionView"
  s.version      = "1.0.5"
  s.summary      = "Hybrid scroll collection view."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
                   A collection for hybrid scrolling, you can use a swipe list in a collection footer.
                   DESC

  s.homepage     = "https://coding.net/u/roylee/p/hybrid_collection/git"

  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE" }


  s.author             = { "Roylee" => "roylee-stillway@163.com" }

  s.platform     = :ios
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://git.coding.net/roylee/hybrid_collection.git", :tag => "#{s.version}" }
  s.source_files  = "hybrid/Hybrid/**/*.{h,m}"
  s.public_header_files = "hybrid/Hybrid/**/*.h"

  s.requires_arc = true

end
