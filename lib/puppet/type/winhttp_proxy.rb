Puppet::Type.newtype(:winhttp_proxy) do
  @doc = 'Manage Windows system proxy (i.e. WinHTTP Proxy) settings.
  '

  ensurable do
    desc 'How to ensure proxy settings are defined'
    defaultvalues
    defaultto :present
  end

  newparam(:name) do
    desc 'Resource name. Should be "proxy".'
    isnamevar
    newvalues(:proxy)
  end

  newproperty(:proxy_server) do
    desc %(Proxy server for use for http and/or https protocol.

    Examples:
    * myproxy
    * myproxy:80
    * http=proxy.example.com;https=proxy.example.org)
    validate do |values|
      values.split(';').each do |value|
        unless %r{^[=a-z._-]+(:\d+)?$}.match?(value)
          raise ArgumentError, "proxy_server item %s is invalid. Examples: 'myproxy', 'myproxy:80', 'http=proxy.example.com'" % value
        end
      end
    end
  end

  newproperty(:bypass_list, array_matching: :all) do
    desc %q{An array of sites that should be visited bypassing the proxy
      (use "<local>" to bypass all short name hosts).

    Examples:
    * ['*.foo.com']
    * ['<local>', 'example.org']}
    validate do |values|
      values.split(';').each do |value|
        unless value =~ (%r{^[*a-z0-9._-]+$}) || (value == '<local>')
          raise ArgumentError, "bypass_list item %s is invalid. Examples: '*.foo.com', 'bar', '<local>'" % value
        end
      end
    end
  end
end
