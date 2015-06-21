class Data_cfy_app

  SLEEP_TIME = 1
  GIVEUP_TICKS = 120 / SLEEP_TIME
  HEALTH_TICKS = 5 / SLEEP_TIME

  def initialize(owner)
    @ec2_main = owner
  end

  def find_all_apps()
    conn = @ec2_main.environment.connection
    return {} if conn == nil
    conn.list_apps || []
  end

  def find_all_states()
    app_states = []
    states = {}
    apps = find_all_apps()
    apps.each do |app_info|
      states[app_info[:state]] ? states[app_info[:state]] += 1 : states[app_info[:state]] = 1
    end
    states.each do |state_key, state_value|
      if state_value > 0
        app_states << {:label => I18n.t('apps.model.' + state_key.to_s, :default => state_key.capitalize),
        :color => state_color(state_key), :data => state_value}
      end
    end
    app_states
  end

  def find(name)
    conn = @ec2_main.environment.connection
    return {} if conn == nil
    app_info = conn.app_info(name) || {}
    unless app_info.empty?
      app_info[:instances_info] = find_app_instances(name)
      app_info[:crashes] = find_app_crashes(name)
      app_info[:instances_states] = find_app_instances_states(app_info)
      app_info[:env].collect! { |env|
        var, value = env.split("=")
        {:var_name => var, :var_value => value}
      }
    end
    app_info
  end

  def find_app_instances(name)
    conn = @ec2_main.environment.connection
    return [] if conn == nil
    app_instances = []
    instances_info = conn.app_instances(name) || {}
    instances_stats = instances_info[:instances].blank? ? [] : @cf_client.app_stats(name) || []
    instances_info.each do |instances, instances_value|
      instances_value.each do |info|
        stats = nil
        instances_stats.each do |stats_value|
          if stats_value[:instance] == info[:index]
            stats = stats_value[:stats]
            break
          end
        end
        app_instances << {:instance => info[:index], :state => info[:state], :stats => stats}
      end
    end
    app_instances
  end

  def find_app_crashes(name)
    conn = @ec2_main.environment.connection
    return {} if conn == nil
    conn.app_crashes(name)[:crashes] || {}
  end

  def find_app_instances_states(app_info)
    app_instances_states = []
    return app_instances_states unless app_info

    states = {}
    if app_info[:instances_info].empty?
      states["STOPPED"] = app_info[:instances]
    else
      app_info[:instances_info].each do |instance_info|
        states[instance_info[:state]] ? states[instance_info[:state]] += 1 : states[instance_info[:state]] = 1
      end
    end
    states["CRASHED"] = app_info[:crashes].length
    states.each do |state_key, state_value|
      if state_value > 0
        app_instances_states << {:label => I18n.t('apps.model.' + state_key.to_s, :default => state_key.capitalize),
        :color => state_color(state_key), :data => state_value}
      end
    end
    app_instances_states
  end

  def create(name, instances, memsize, url, framework, runtime, service)
    #raise I18n.t('apps.model.name_invalid', :name => name) if (name =~ /^[\w-]+$/).nil?
    conn = @ec2_main.environment.connection
    return {} if conn == nil
    #begin
    #  app_info = conn.app_info(name)
    #rescue
    #  app_info = nil
    #end
    #raise I18n.t('apps.model.already_exists') unless app_info.nil?
    #raise I18n.t('apps.model.instances_blank') if instances.blank?
    #raise I18n.t('apps.model.instances_numeric') if (instances =~ /^\d+$/).nil?
    #raise I18n.t('apps.model.instances_lt1') if instances.to_i < 1
    #raise I18n.t('apps.model.memsize_blank') if memsize.blank?
    #raise I18n.t('apps.model.memsize_numeric') if (memsize =~ /^\d+$/).nil?
    #raise I18n.t('apps.model.memsize_unavailable') unless check_has_capacity_for(instances.to_i * memsize.to_i)
    #raise I18n.t('apps.model.url_blank') if url.blank?
    #raise I18n.t('apps.model.framework_blank') if framework.blank?
    #raise I18n.t('apps.model.runtime_blank') if runtime.blank?
    #raise I18n.t('apps.model.framework_invalid') unless valid_framework_and_runtime?(framework, runtime)
    manifest = {
      :name => name,
      :instances => instances,
      :resources => {:memory => memsize},
      :uris => [url],
      :staging => {:framework => framework, :runtime => runtime},
    }
    if service != nil and service != ""
      manifest[:services] = [service]
    end
    conn.create_app(name, manifest)
  end

  def start(name)
    conn = @ec2_main.environment.connection
    return {} if conn == nil
    app = conn.app_info(name)
    app[:state] = "STARTED"
    conn.update_app(name, app)
    count = 0
    start_time = Time.now.to_i
    loop do
      sleep SLEEP_TIME
      break if app_started_properly(name, count > HEALTH_TICKS)
      raise 'Start Failed' unless app_crashes(name, start_time).empty?
      count += 1
      raise 'Start Took Too Long' if count > GIVEUP_TICKS
    end
    conn.app_info(name) || {}
  end

  def stop(name)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    conn = @ec2_main.environment.connection
    return {} if conn == nil
    app = conn.app_info(name)
    app[:state] = "STOPPED"
    conn.update_app(name, app)
    app
  end

  def restart(name)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    app = stop(name)
    app = start(name)
  end

  def delete(name)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    conn = @ec2_main.environment.connection
    return {} if conn == nil
    conn.delete_app(name)
  end

  def set_instances(name, instances)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.instances_blank') if instances.blank?
    #raise I18n.t('apps.model.instances_numeric') if (instances =~ /^\d+$/).nil?
    #raise I18n.t('apps.model.instances_lt1') if instances.to_i < 1
    conn = @ec2_main.environment.connection
    return {} if conn == nil
    app = conn.app_info(name)
    current_instances = app[:instances]
    wanted_mem = instances.to_i * app[:resources][:memory]
    wanted_mem = wanted_mem - (current_instances * app[:resources][:memory]) if app[:state] != 'STOPPED'
    raise 'Memory Size Unavailable' unless check_has_capacity_for(wanted_mem)
    if instances.to_i != current_instances.to_i
      app[:instances] = instances
      conn.update_app(name, app)
    end
    true
  end

  def set_memsize(name, memsize)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.memsize_blank') if memsize.blank?
    #raise I18n.t('apps.model.memsize_numeric') if (memsize =~ /^\d+$/).nil?
    conn = @ec2_main.environment.connection
    return {} if conn == nil
    app = conn.app_info(name)
    current_memory = app[:resources][:memory]
    wanted_mem = memsize.to_i * app[:instances]
    wanted_mem = wanted_mem - (current_memory * app[:instances]) if app[:state] != 'STOPPED'
    raise 'Memory Size Unavailable' unless check_has_capacity_for(wanted_mem)
    if memsize.to_i != current_memory.to_i
      app[:resources][:memory] = memsize
      conn.update_app(name, app)
      check_app_for_restart(name)
    end
    true
  end

  def set_var(name, var_name, var_value, restart = "true")
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.envvar_blank') if var_name.blank?
    #raise I18n.t('apps.model.envvar_invalid', :var_name => var_name) if (var_name =~ /^[\w-]+$/).nil?
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    app = conn.app_info(name)
    envvars = app[:env] || []
    var_exists = nil
    envvars.each do |env|
      var, value = env.split('=')
      if var == var_name
        var_exists = env
        break
      end
    end
    envvars.delete(var_exists) if var_exists
    envvars << "#{var_name}=#{var_value}"
    app[:env] = envvars
    conn.update_app(name, app)
    check_app_for_restart(name) if restart == "true"
    var_exists
  end

  def unset_var(name, var_name, restart = "true")
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.envvar_blank') if var_name.blank?
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    app = conn.app_info(name)
    envvars = app[:env] || []
    var_deleted = nil
    envvars.each do |env|
      var, value = env.split('=')
      if var == var_name
        var_deleted = env
        break
      end
    end
    if var_deleted
      envvars.delete(var_deleted)
      app[:env] = envvars
      conn.update_app(name, app)
      check_app_for_restart(name) if restart == "true"
    else
      raise "Environment Variable #{var_name} Not Set"
    end
    var_deleted
  end

  def bind_service(name, service)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.service_blank') if service.blank?
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    app = conn.app_info(name)
    services = app[:services] || []
    service_exists = services.index(service)
    if service_exists
      raise "Service #{service} exists"
    else
      app[:services] = services << service
      conn.update_app(name, app)
      check_app_for_restart(name)
    end
    true
  end

  def unbind_service(name, service)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.service_blank') if service.blank?
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    app = conn.app_info(name)
    services = app[:services] || []
    service_deleted = services.delete(service)
    if service_deleted
      app[:services] = services
      conn.update_app(name, app)
      check_app_for_restart(name)
    else
      raise "Service #{service} not binded"
    end
    true
  end

  def map_url(name, url)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.url_blank') if url.blank?
    url = url.strip.gsub(/^http(s*):\/\//i, '').downcase
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    app = conn.app_info(name)
    uris = app[:uris] || []
    url_exists = uris.index(url)
    if url_exists
      raise "Url #{url} exists"
    else
      app[:uris] = uris << url
      conn.update_app(name, app)
    end
    url
  end

  def unmap_url(name, url)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.url_blank') if url.blank?
    url = url.strip.gsub(/^http(s*):\/\//i, '').downcase
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    app = conn.app_info(name)
    uris = app[:uris] || []
    url_deleted = uris.delete(url)
    if url_deleted
      app[:uris] = uris
      conn.update_app(name, app)
    else
      raise "Url #{url} not mapped"
    end
    url
  end

  def upload_app(name, zipfile, resource_manifest = [])
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.zipfile_blank') if zipfile.blank?
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    conn.upload_app(name, zipfile, resource_manifest)
  end

  def upload_app_from_git(name, gitrepo, gitbranch)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.name_invalid', :name => name) if (name =~ /^[\w-]+$/).nil?
    #raise I18n.t('apps.model.gitrepo_blank') if gitrepo.blank?
    #raise I18n.t('apps.model.gitbranch_blank') if gitbranch.blank?
    app_bits_tmpdir = get_app_bits_tmpdir()
    repodir = app_bits_tmpdir.join(name).to_s
    Utils::GitUtil.git_clone(gitrepo, gitbranch, repodir)
    zipfile = app_bits_tmpdir.join(name + ".zip").to_s
    files = get_files_to_pack(repodir)
    raise 'No files' if files.empty?
    Utils::ZipUtil.pack_files(zipfile, files)
    files.each { |f| f[:fn] = f[:zn]}
    upload_app(name, zipfile, files)
    ensure
    FileUtils.rm_f(zipfile) if zipfile
    FileUtils.rm_rf(repodir, :secure => true) if repodir
  end

  def download_app(name)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    app_bits_tmpdir = get_app_bits_tmpdir()
    zipfile = app_bits_tmpdir.join(name + ".zip").to_s
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    app_bits = conn.download_app(name)
    File.open(zipfile, "w") {|f| f.write(app_bits.force_encoding("utf-8").encode) }
    zipfile
  end

  def view_file(name, path, instance = 0)
    #raise I18n.t('apps.model.name_blank') if name.blank?
    #raise I18n.t('apps.model.path_blank') if path.blank?
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    contents = conn.app_files(name, path, instance) || []
  end

  private

  def app_crashes(name, since = 0)
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    crashes = conn.app_crashes(name)[:crashes] || {}
    crashes.delete_if {|crash| crash[:since] < since}
    crashes
  end

  def app_started_properly(name, error_on_health)
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    app = conn.app_info(name)
    case health(app)
    when 'N/A'
      raise 'Undetermined State' if error_on_health
      return false
    when 'RUNNING'
      return true
    else
      return false
    end
  end

  def check_app_for_restart(name)
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    app = conn.app_info(name) || {}
    restart(name) if app[:state] == 'STARTED'
  end

  def check_has_capacity_for(wanted_mem)
    available_for_use = $ec2_main.environment.cfy_system.find_available_memory()
    (available_for_use - wanted_mem.to_i) >= 0
  end

  def check_resources(resources = [])
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    conn.check_resources(resources)
  end

  def get_app_bits_tmpdir()
    # this will fail
    Rails.root.join('tmp').join('app-bits')
  end

  def get_files_to_pack(repodir)
    files = []
    total_size = 0
    Dir.glob("#{repodir}/**/*", File::FNM_DOTMATCH).select do |f|
      process = true
      %w(*/.git */.git/*).each { |e| process = false if File.fnmatch(e, f) }
      %w(.. . *~ #*# *.log).each { |e| process = false if File.fnmatch(e, File.basename(f)) }
      if process
        if !File.directory?(f) && File.exists?(f)
          files << {:fn => f, :zn => f.sub("#{repodir}/", ""), :size => File.size(f), :sha1 => Digest::SHA1.file(f).hexdigest}
          total_size += File.size(f)
        end
      end
    end
    if total_size > (64*1024)
      matched_files = check_resources(files)
      files = files - matched_files if matched_files
    end
    files
  end

  def health(app)
    return 'N/A' unless (app and app[:state])
    return 'STOPPED' if app[:state] == 'STOPPED'

    health = nil
    healthy_instances = app[:runningInstances]
    expected_instances = app[:instances]
    if app[:state] == "STARTED" && expected_instances > 0 && healthy_instances
      health = format("%.3f", healthy_instances.to_f / expected_instances).to_f
    end

    return 'RUNNING' if health && health == 1.0
    return "#{(health * 100).round}%" if health
    return 'N/A'
  end

  def state_color(state)
    color = case state
    when "RUNNING" then "#7FDB49"
    when "STARTED" then "#7FDB49"
    when "STARTING" then "#5BDED3"
    when "STOPPED" then "#C70E17"
    when "FLAPPING" then "#FF8C00"
    when "DOWN" then "#941218"
      #when "CRASHED" then "#F71823"
      #when "DEA_SHUTDOWN" then "#F71823"
      #when "DEA_EVACUATION" then "#F71823"
    else "#F71823"
    end
  end

  def valid_framework_and_runtime?(framework, runtime)
    conn = @ec2_main.environment.connection
    return nil if conn == nil
    system = System.new(conn)
    frameworks = system.find_all_frameworks()
    frameworks.each do |fwk_name, fwk|
      fwk[:runtimes].each do |run|
        return true if (fwk[:name] == framework && run[:name] == runtime)
      end
    end
    false
  end
end