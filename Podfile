# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

# Pod for each target.
target 'hybrid' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!
  
  pod 'SnapKit'
  
  pod 'SDWebImage'
  
  # IGListKit (A better UICollectionView)
  pod 'IGListKit'
  
  # Pager view
  pod 'Parchment'
#  pod 'VTMagic'
  
  # Alert
  pod 'SVProgressHUD'
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      puts "target name is: #{target.name}"
      if target.name == 'SVProgressHUD'
        target.build_configurations.each do |config|
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)','DEBUG=1', 'SV_APP_EXTENSIONS=1']
        end
      end
    end
  end
end

