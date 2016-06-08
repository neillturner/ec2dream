#require 'fog'
require 'json'

class Vcloud_conn

  # also see https://github.com/Cysource/vcloud-client
  #organizations
  #  organization
  #    vdcs -> vdc -> vapps -> vapp -> vms -> vm -> customizations -> script
  #                                              -> network
  #                                              -> disks -> disk
  #                                              -> tags -> tag
  #                                              -> power_on
  #    networks -> network
  #    catalogs -> catalog -> catalog_items -> catalog_item -> instantiate_vapp
  #    medias -> media

  def initialize(conn)
    @conn = conn
  end

  def hashify(o)
    h = {}
    o.attributes.each do |a|
      if a[1].to_s != 'NonLoaded'
        cmd = "h['#{a[0]}']='#{a[1]}'"
        #puts "#{cmd}"
        eval(cmd)
      end
    end
    return h
  end

  def get_organization(name)
    @conn.organizations.get_by_name(name)
  end

  def get_organizations
    data = []
    @conn.organizations.each do |item|
      data.push(hashify(item))
    end
    return data
  end

  def get_catalogs(o=nil)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    org = @conn.organizations.get_by_name(o)
    data = []
    org.catalogs.each do |item|
      data.push(hashify(item))
    end
    return data
  end

  def get_catalogs_items(o=nil,c)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    org = @conn.organizations.get_by_name(o)
    catalog = org.catalogs.get_by_name(c)
    data = []
    catalog.catalog_items.each do |item|
      data.push(hashify(item))
    end
    return data
  end

  def get_networks(o=nil)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    org = @conn.organizations.get_by_name(o)
    data = []
    org.networks.each do |item|
      data.push(hashify(item))
    end
    return data
  end

  def get_vdcs(o=nil)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    org = @conn.organizations.get_by_name(o)
    data = []
    org.vdcs.each do |item|
      puts "*** item #{hashify(item)}"
      data.push(hashify(item))
    end
    return data
  end

  def get_vapps(o=nil,v)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    org = @conn.organizations.get_by_name(o)
    vdc = org.vdcs.get_by_name(v)
    data = []
    vdc.vapps.each do |item|
      data.push(hashify(item))
    end
    return data
  end

  def get_vms(o=nil,v=nil,va=nil)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    v = $ec2_main.settings.get('AVAILABILITY_ZONE') if v.nil?
    org = @conn.organizations.get_by_name(o)
    vdc = org.vdcs.get_by_name(v)
    puts "*** vdc '#{v}' #{vdc.name}"
    data = []
    vdc.vapps.each do |vapp|
      vapp_name = vapp.name
      puts "*** vapp #{vapp.name}"
      vapp = vdc.vapps.get_by_name(va)
      vapp.vms.each do |item|
        h = hashify(item)
        h[:vapp] = vapp_name
        data.push(h)
      end
    end
    return data
  end

  def get_vm_customization(o=nil,v,va,m)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    org = @conn.organizations.get_by_name(o)
    vdc = org.vdcs.get_by_name(v)
    vapp = vdc.vapps.get_by_name(va)
    vm = vapp.vms.get_by_name(m)
    data = []
    data.push(hashify(vm.customization))
    return data
  end

  def get_vm_network(o=nil,v,va,m)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    org = @conn.organizations.get_by_name(o)
    vdc = org.vdcs.get_by_name(v)
    vapp = vdc.vapps.get_by_name(va)
    vm = vapp.vms.get_by_name(m)
    data = []
    data.push(hashify(vm.network))
    return data
  end

  def get_vm_disks(o=nil,v,va,m)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    org = @conn.organizations.get_by_name(o)
    vdc = org.vdcs.get_by_name(v)
    vapp = vdc.vapps.get_by_name(va)
    vm = vapp.vms.get_by_name(m)
    data = []
    vm.disks.each do |item|
      data.push(hashify(item))
    end
    return data
  end

  def get_vm_tags(o=nil,v,va,m)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    org = @conn.organizations.get_by_name(o)
    vdc = org.vdcs.get_by_name(v)
    vapp = vdc.vapps.get_by_name(va)
    vm = vapp.vms.get_by_name(m)
    data = []
    vm.tags.each do |item|
      data.push(hashify(item))
    end
    return data
  end

  def get_tasks(o=nil)
    o = $ec2_main.settings.get('AMAZON_ACCOUNT_ID') if o.nil?
    org = @conn.organizations.get_by_name(o)
    data = []
    org.tasks.each do |item|
      data.push(hashify(item))
    end
    return data
  end

end

