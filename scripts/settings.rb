#
# EC2 Settings for ruby scripts
# add any extra settings here
#
class Settings
  def Settings.AMAZON_PUBLIC_KEY
    return '<AMAZON_ACCESS_KEY_ID>'
  end
  def Settings.AMAZON_PRIVATE_KEY
      return '<AMAZON_SECRET_ACCESS_KEY>'
  end
  def Settings.REGION
      return '<EC2_URL>'
  end    
end  