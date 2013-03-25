require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class CFY_AppUploadDialog < FXDialogBox

  def initialize(owner, parm)
    puts "CFY_AppUploadDialog.initialize"
    @ec2_main = owner
    @created = false
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create    
    super(owner, "App Upload", :opts => DECOR_ALL, :width => 550, :height => 150)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "App Name" )
    name = FXTextField.new(frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    name.text = parm 
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Zip File" )
    zipfile = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    zipfile_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    zipfile_button.icon = @magnifier
    zipfile_button.tipText = "Browse..."
    zipfile_button.connect(SEL_COMMAND) do
        dialog = FXFileDialog.new(frame1, "Select Zipfile")
        dialog.patternList = [
           "Zipfiles (*.*)"
        ]
        dialog.selectMode = SELECTFILE_EXISTING
        if dialog.execute != 0
           zipfile.text = dialog.filename
        end
    end
    FXLabel.new(frame1, "Resource Manifest" )
    resource_manifest = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    resource_manifest_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    resource_manifest_button.icon = @magnifier
    resource_manifest_button.tipText = "Browse..."
    resource_manifest_button.connect(SEL_COMMAND) do
        dialog = FXFileDialog.new(frame1, "Select Resource Manifest")
        dialog.patternList = [
           "Manifest files (*.*)"
        ]
        dialog.selectMode = SELECTFILE_EXISTING
        if dialog.execute != 0
           resource_manifest.text = dialog.filename
        end
    end    
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Upload   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if zipfile.text == nil or zipfile.text == ""
         error_message("Error","Zip File not specified")
       else
         upload(name.text, zipfile.text, resource_manifest.text)
         self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end  
    end
    cancel = FXButton.new(frame2, "   &Cancel   ", nil, self, ID_CANCEL, FRAME_RAISED|LAYOUT_CENTER_X|LAYOUT_SIDE_BOTTOM)
    cancel.connect(SEL_COMMAND) do |sender, sel, data|
            self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end  
  end 
 
 
  def upload(name, zipfile, resource_manifest)
     begin
        # ignore resource_manifest for now
        r = @ec2_main.environment.cfy_app.upload_app(name, zipfile)
        @created = true
     rescue
        error_message("Upload App Failed",$!)
     end      
 end 
   
  def saved
     @created
  end
  
  def created
     @created
  end
  
  def success
     @created
  end

end
