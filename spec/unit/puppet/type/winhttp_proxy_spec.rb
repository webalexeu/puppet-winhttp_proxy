require 'spec_helper'

describe Puppet::Type.type(:winhttp_proxy) do
  let :winhttp_proxy do
    Puppet::Type.type(:winhttp_proxy).new(name: 'proxy', proxy_server: 'proxy.example.org')
  end

  # =========================================================================
  # name
  it 'does not accept a name different than proxy' do
    expect {
      Puppet::Type.type(:winhttp_proxy).new(
          name: 'something else',
        )
    }.to raise_error(Puppet::Error, %r{Invalid value "something else". Valid values are proxy.})
  end

  # =========================================================================
  # proxy_server
  it 'accepts simple proxy_server' do
    proxy = 'proxy.example.com'
    winhttp_proxy[:proxy_server] = proxy
    expect(winhttp_proxy[:proxy_server]).to eq(proxy)
  end
  it 'accepts complex proxy_server' do
    proxy = 'http=proxy-cluster.example.org:3128;https=proxy_ms.example.com'
    winhttp_proxy[:proxy_server] = proxy
    expect(winhttp_proxy[:proxy_server]).to eq(proxy)
  end
  it 'does not accept an invalid wildcard proxy_server' do
    expect {
      Puppet::Type.type(:winhttp_proxy).new(
          name: 'proxy',
          proxy_server: '*.example.org',
        )
    }.to raise_error(Puppet::Error, %r{proxy_server item \*.example.org is invalid. Examples: 'myproxy', 'myproxy:80', 'http=proxy.example.com'})
  end

  # =========================================================================
  # bypass_list
  it 'accepts empty bypass_list' do
    bp = []
    winhttp_proxy[:bypass_list] = bp
    expect(winhttp_proxy[:bypass_list]).to eq(bp)
  end
  it 'accepts correct bypass_list' do
    bp = ['<local>', 'example.org']
    winhttp_proxy[:bypass_list] = bp
    expect(winhttp_proxy[:bypass_list]).to eq(bp)
  end
end
