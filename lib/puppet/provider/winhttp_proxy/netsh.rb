Puppet::Type.type(:winhttp_proxy).provide(:netsh, parent: Puppet::Provider) do
  confine operatingsystem: :windows
  defaultfor operatingsystem: :windows

  desc 'Windows Proxy'

  # Actually, Windows as different settings under 32-bit or 64-bit
  # How can people pay for this crappy software?!
  # FIXME Handle the WOW64 proxy too
  def self.netsh_command
    if File.exist?("#{ENV['SYSTEMROOT']}\\System32\\netsh.exe")
      "#{ENV['SYSTEMROOT']}\\System32\\netsh.exe"
    else
      'netsh.exe'
    end
  end

  initvars
  mk_resource_methods

  commands netsh: netsh_command

  def self.instances
    proxy = {
      'ensure' => :absent
    }
    cmd = [ 'cmd.exe', '/c', command(:netsh), 'winhttp', 'dump' ]
    raw = Puppet::Util::Execution.execute(cmd)
    _status = raw.exitstatus
    instances = []
    context = []
    raw.each_line do |line|
      next if %r{^\s*(#|$)}.match?(line)
      if line =~ %r{^pushd (.*)$}
        context << Regexp.last_match(1)
        next
      end
      if %r{^popd$}.match?(line)
        context.pop
        next
      end
      if (context == [ 'winhttp' ]) && line =~ (%r{^reset proxy$})
        next
      end
      if (context == [ 'winhttp' ]) && line =~ (%r{^set proxy proxy-server="([^"]+)"( bypass-list="([^"]+)")?$})
        proxy = {
          name: :proxy,
          ensure: :present,
          proxy_server: Regexp.last_match(1),
          bypass_list: [],
        }
        if Regexp.last_match(3)
          proxy[:bypass_list] = Regexp.last_match(3).split(';')
        end
        instances << new(proxy)
        next
      end
      Puppet.warning('Unable to parse line %s' % line)
    end
    instances
  end

  def self.prefetch(resources)
    instances.each do |instance|
      if (proxy = resources[instance.name])
        proxy.provider = instance
      end
    end
  end

  # Exists
  def exists?
    !(@property_hash[:ensure] == :absent or @property_hash.empty?)
  end

  # Keep resource properties, flush will actually apply
  def create
    @property_hash = {
      ensure: :present,
      proxy_server: @resource[:proxy_server],
      bypass_list: @resource[:bypass_list]
    }
  end

  # Unlike create we actually immediately delete the item.
  def destroy
    netsh('winhttp', 'reset', 'proxy')
    @property_hash.clear
  end

  def flush
    cmd = [ 'cmd.exe', '/c', command(:netsh), 'winhttp', 'set', 'proxy', 'proxy-server="%s"' % @property_hash[:proxy_server],
            'bypass-list="%s"' % (@property_hash[:bypass_list].respond_to?('join') ? @property_hash[:bypass_list].join(';') : @property_hash[:bypass_list]) ]
    raw = Puppet::Util::Execution.execute(cmd)
    _status = raw.exitstatus
  end
end
