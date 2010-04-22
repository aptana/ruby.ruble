require 'ruble'
require 'ruble/platform'

# Only define command on Windows
if Ruble.platforms.include? :windows
command 'Setup Ruby and Debugger' do |c|
  c.input = :none
  c.output = :discard
  c.key_binding = "M1+M2+S"
  c.invoke do |context|
    require 'open-uri'
    require 'tmpdir'
    require 'fileutils'
    
    old_log_level = Ruble::Logger.log_level
    Ruble::Logger.log_level = :info
    
    # URLS for files to download
    seven_zip_url = 'http://downloads.sourceforge.net/sevenzip/7z465.exe'
    ruby_installer_url = 'http://rubyforge.org/frs/download.php/69034/rubyinstaller-1.8.7-p249-rc2.exe'
    devkit_url = 'http://rubyforge.org/frs/download.php/66888/devkit-3.4.5r3-20091110.7z'
    
    tmp_dir = Dir.tmpdir    
    installer_file = File.join(tmp_dir, "rubyinstaller.exe")
        
    # Is ruby already installed?
    ruby_installed = IO.popen("ruby -v") {|io| io.read }.start_with? "ruby"
    if !ruby_installed
      # Download ruby installer
      unless File.exist? installer_file
        Ruble::Logger.log_info "Downloading Ruby Installer"
        open(ruby_installer_url) do |io|
          open(installer_file, "wb") {|file| file.write io.read }
        end
      end

      # Run ruby installer
      Ruble::Logger.log_info "Running Ruby Installer..."
      IO.popen(installer_file) {|io| io.read } # FIXME Wait for installer to finish here!   
    else
      Ruble::Logger.log_info "Ruby already installed"
    end
    
    # Determine where user installed to...
    Ruble::Logger.log_info "Determining Ruby Installation directory"
    install_dir = IO.popen("ruby -e 'require \"rbconfig\"; puts RbConfig::CONFIG[\"bindir\"]'") {|io| io.read }
    install_dir = File.expand_path(File.join(install_dir.chomp, ".."))
    Ruble::Logger.log_info install_dir
    
    devkit_installed = File.exist?(File.join(install_dir, "devkit"))    
    if !devkit_installed
      devkit_download_location = File.join(install_dir, 'devkit.7z')
      
      # Download devkit
      unless File.exist? devkit_download_location
        Ruble::Logger.log_info "Downloading Ruby DevKit (to compile native gems)"
        open(devkit_url) do |io|
          open(devkit_download_location, "wb") {|file| file.write io.read }
        end
      end
      
      # Download and install 7-zip if we need to...
      # FIXME If ruby is installed and so is devkit, no need to do this!
      seven_zip_exe = path_that_exists(["/Program Files/7-Zip/7z.exe", "/Program Files (x86)/7-zip/7z.exe"])
      unless File.exist? seven_zip_exe
        seven_zip_download_file = File.join(tmp_dir, "7zip_install.exe")
        
        Ruble::Logger.log_info "Downloading 7-zip"
        open(seven_zip_url) do |io|
          open(seven_zip_download_file, "wb") {|file| file.write io.read }
        end
        
        Ruble::Logger.log_info "Running 7-zip Installer..."
        IO.popen(seven_zip_download_file) {|io| io.read }
        # FIXME Wait for installer to finish here!
        
        seven_zip_exe = path_that_exists(["/Program Files/7-Zip/7z.exe", "/Program Files (x86)/7-zip/7z.exe"])
      else
        Ruble::Logger.log_info "7-Zip already installed"
      end
      
      # Unzip devkit into install location
      Ruble::Logger.log_info "Unzipping Ruby DevKit using 7-zip"
      Dir.chdir(install_dir)
      unzip_cmd = "#{seven_zip_exe} x -y devkit.7z" #.gsub('/', '\\')
      Ruble::Logger.log_info "Running: #{unzip_cmd}"
      `#{unzip_cmd}`     
    else
      Ruble::Logger.log_info "Ruby DevKit already installed"
    end
    
    # TODO Will ruby-debug-ide actually install through our terminal?
    # Run 'gem install ruby-debug-ide' in devkit's msys
    Ruble::UI.simple_notification(:title => 'Install Debugger gems', :summary => "Ruby DevKit's bundled MSYS shell will now open.\n\nPlease run 'gem install ruby-debug-ide' to install the native ruby debugger gems into your system.\n\nIf gems fail to install during native code compilation in the future, try running the devkit/msys/1.0.11/msys.bat shell and executing the install from there.")
    msys_bat = File.join(install_dir, "devkit", "msys", "1.0.11", "msys.bat")
    IO.popen(msys_bat)
    # FIXME Can we send the gem install commands to the shell ourselves somehow?
    
    # TODO Should we also install rails now?
    #Ruble::Terminal.open("gem install rails")
    
    Ruble::Logger.log_level = old_log_level
  end
end

def path_that_exists(array = [])
  require 'java'
  # For some reason JRuby needs the drive prefix for File.exist?
  drives = java.io.File.listRoots.map {|r| r.toString()[0..-2] } 
  array.each do |filepath|
    drives.each {|d| return (d + filepath) if File.exist?(d + filepath) }
  end
  array.first # Just return the first one, though none exist...
end    
end