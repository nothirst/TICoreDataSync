Pod::Spec.new do |s|
  s.name         = "TICoreDataSync"
  s.version      = "1.0.2"
  s.summary      = "Automatic synchronization for Core Data Apps, between any combination of Mac OS X and iOS"
  s.homepage	 = "http://nothirst.github.io/TICoreDataSync"
  s.license      = "MIT"
  s.authors      = { "Tim Isted" => "git@timisted.com", 
  					 "Michael Fey" => "michael@fruitstandsoftware.com",
  					 "Kevin Hoctor" => "kevin@nothirst.com",
  					 "Christian Beer" => "christian.beer@chbeer.de",
  					 "Tony Arnold" => "tony@thecocoabots.com",
  					 "Danny Greg" => "danny@dannygreg.com" }
  s.ios.deployment_target = '5.1'
  s.osx.deployment_target = '10.7'
  s.source       = { :git => "https://github.com/nothirst/TICoreDataSync.git", :tag => "v1.0.1" }
  s.source_files = 'TICoreDataSync/0[1-6]*/**/*.{h,m}', 'TICoreDataSync/TICoreDataSync.h'
  s.resources = 'TICoreDataSync/05*/*.{plist,txt}'
  s.framework    = 'CoreData', 'Security'
  s.requires_arc = true
  s.ios.dependency 	 'Dropbox-iOS-SDK'
  s.osx.dependency 	 'Dropbox-OSX-SDK'
  s.preserve_path = 'TICoreDataSync/03 Internal Data Model/TICDSSyncChange.xcdatamodel', 'TICoreDataSync/03 Internal Data Model/TICDSSyncChangeSet.xcdatamodeld'

  def s.post_install(target)
    pod_root = config.project_pods_root + 'TICoreDataSync/'
    ['TICDSSyncChange.xcdatamodel', 'TICDSSyncChangeSet.xcdatamodeld'].each do |datamodelfile|
      datamodel = File.basename(datamodelfile)
      momext = File.extname(datamodelfile) == '.xcdatamodel' ? 'mom' : 'momd'
      momd_relative = "TICoreDataSync/03 Internal Data Model/#{datamodel}.#{momext}"
      momd_full = pod_root + momd_relative
      unless momd_full.exist?
        puts "\nCompiling #{datamodelfile} Core Data model\n".yellow if config.verbose?
        model = pod_root + "TICoreDataSync/03 Internal Data Model/#{datamodelfile}"
        command = "xcrun momc '#{model}' '#{momd_full}'"
        command << " 2>&1 > /dev/null" unless config.verbose?
        unless system(command)
          raise ::Pod::Informative, "Failed to compile #{datamodelfile} Core Data model"
        end
      end

      File.open(File.join(config.project_pods_root, target.target_definition.copy_resources_script_name), 'a') do |file|
        file.puts "install_resource 'TICoreDataSync/#{momd_relative}'"
      end
    end
    
    prefix_header = config.project_pods_root + target.prefix_header_filename
    prefix_header.open('a') do |file|
      file.puts(%{#ifdef __OBJC__\n#import <CoreData/CoreData.h>\n#endif})
    end
  end
end
