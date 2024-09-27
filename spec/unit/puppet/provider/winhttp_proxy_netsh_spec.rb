require 'spec_helper'

describe Puppet::Type.type(:winhttp_proxy).provider(:netsh) do
  before(:each) do
    described_class.stubs(:command).with(:netsh).returns 'netsh'
  end
  # =========================================================================
  # No proxy:
  #   reset proxy
  # =========================================================================
  context 'no proxy' do
    let :instances do
      output = <<-EOS



# -----------------------------------------
# WinHTTP Proxy Configuration
# -----------------------------------------
pushd winhttp

reset proxy

popd

# End of WinHTTP Proxy Configuration


      EOS
      Puppet::Util::Execution.expects(:execute).with(['cmd.exe', '/c', 'netsh', 'winhttp', 'dump']).at_least_once.returns(
        Puppet::Util::Execution::ProcessOutput.new(output, 0),
      )
      _instances = described_class.instances
    end

    it 'has no instance' do
      expect(instances.count).to eq(0)
    end
  end

  # =========================================================================
  # No proxy -> simple proxy:
  #   reset proxy -> set proxy proxy-server="localproxy:3128"
  # =========================================================================
  context 'no proxy -> simple proxy' do
    let :resource do
      Puppet::Type.type(:winhttp_proxy).new(
        name: 'proxy',
        provider: :netsh,
        proxy_server: 'localproxy:3128',
      )
    end

    let :instance do
      instance = described_class.new(resource)
      instance.create
      instance
    end

    it 'creates an instance' do
      Puppet::Util::Execution.expects(:execute).with(['cmd.exe', '/c', 'netsh', 'winhttp', 'set', 'proxy', 'proxy-server="localproxy:3128"', 'bypass-list=""']).once.returns(
        Puppet::Util::Execution::ProcessOutput.new('', 0),
      )
      instance.flush
    end
  end

  # =========================================================================
  # Simple proxy:
  #   set proxy proxy-server="myproxy:3128"
  # =========================================================================
  context 'simple proxy' do
    let :instances do
      output = <<-EOS


# -----------------------------------------
# WinHTTP Proxy Configuration
# -----------------------------------------
pushd winhttp

set proxy proxy-server="myproxy:3128"

popd

# End of WinHTTP Proxy Configuration


      EOS

      Puppet::Util::Execution.expects(:execute).with(['cmd.exe', '/c', 'netsh', 'winhttp', 'dump']).at_least_once.returns(
        Puppet::Util::Execution::ProcessOutput.new(output, 0),
      )
      _instances = described_class.instances
    end

    it 'has one instance' do
      expect(instances.count).to eq(1)
    end

    it 'instance should exists' do
      expect(instances.first.exists?).to eq(true)
    end

    it 'instance should have correct proxy-server' do
      expect(instances.first.proxy_server).to eq('myproxy:3128')
    end

    it 'instance should have correct bypass-list' do
      expect(instances.first.bypass_list).to eq([])
    end
  end

  # =========================================================================
  # Simple proxy with bypass list:
  #   set proxy proxy-server="myproxy.example.org" bypass-list="<local>;*.example.org"
  # =========================================================================
  context 'simple proxy with bypass list' do
    let :instances do
      output = <<-EOS


# -----------------------------------------
# WinHTTP Proxy Configuration
# -----------------------------------------
pushd winhttp

set proxy proxy-server="myproxy.example.org" bypass-list="<local>;*.example.org"


popd

# End of WinHTTP Proxy Configuration

      EOS

      Puppet::Util::Execution.expects(:execute).with(['cmd.exe', '/c', 'netsh', 'winhttp', 'dump']).at_least_once.returns(
        Puppet::Util::Execution::ProcessOutput.new(output, 0),
      )
      _instances = described_class.instances
    end

    it 'has one instance' do
      expect(instances.count).to eq(1)
    end

    it 'instance should exists' do
      expect(instances.first.exists?).to eq(true)
    end

    it 'instance should have correct proxy-server' do
      expect(instances.first.proxy_server).to eq('myproxy.example.org')
    end

    it 'instance should have correct bypass-list' do
      expect(instances.first.bypass_list).to eq([
                                                  '<local>',
                                                  '*.example.org',
                                                ])
    end
  end

  # =========================================================================
  # Different HTTP and HTTPS proxies with bypass list:
  #   set proxy proxy-server="http=proxy.example.com;https=proxy.example.org" bypass-list="*.example.org;*.example.com"
  # =========================================================================
  context 'simple proxy with bypass list' do
    let :instances do
      output = <<-EOS


# -----------------------------------------
# WinHTTP Proxy Configuration
# -----------------------------------------
pushd winhttp

set proxy proxy-server="http=proxy.example.com;https=proxy.example.org" bypass-list="*.example.org;*.example.com"

popd

# End of WinHTTP Proxy Configuration

      EOS

      Puppet::Util::Execution.expects(:execute).with(['cmd.exe', '/c', 'netsh', 'winhttp', 'dump']).at_least_once.returns(
        Puppet::Util::Execution::ProcessOutput.new(output, 0),
      )
      _instances = described_class.instances
    end

    it 'has one instance' do
      expect(instances.count).to eq(1)
    end

    it 'instance should exists' do
      expect(instances.first.exists?).to eq(true)
    end

    it 'instance should have correct proxy-server' do
      expect(instances.first.proxy_server).to eq('http=proxy.example.com;https=proxy.example.org')
    end

    it 'instance should have correct bypass-list' do
      expect(instances.first.bypass_list).to eq([
                                                  '*.example.org',
                                                  '*.example.com',
                                                ])
    end
  end
end
