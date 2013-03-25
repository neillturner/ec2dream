class Data_cfy_user
  def initialize(owner)
    @ec2_main = owner
  end

  def find_all_users()
    conn = @ec2_main.environment.connection 
    return {} if conn == nil
    begin 
       conn.list_users || []
    rescue
       []
    end
  end

  def find(username)
    conn = @ec2_main.environment.connection 
    return {} if conn == nil  
    user_info = conn.user_info(username) || nil
    # cc's prior to 31143c1 commit doesn't return the admin flag
    if !user_info.nil? && !user_info.has_key?(:admin)
      user_info = nil
      users = find_all_users()
      users.each do |user_item|
        if user_item[:email] == username
          user_info = user_item
          break
        end
      end
    end
    user_info
  end

  def is_admin?(username)
    user_info = find(username)
    return true if !user_info.nil? && user_info[:admin] == true
    false
  end

  def create(username, password)
    conn = @ec2_main.environment.connection 
    return {} if conn == nil  
    conn.create_user(username, password)
  end

  def delete(username)
    conn = @ec2_main.environment.connection 
    return {} if conn == nil  
    conn.delete_user(username)
  end
end