require 'spec_helper'

describe Utils do
  before { StripeMock.start }
  after { StripeMock.stop }

  it "checks http resource exists" do
    Utils.http_resource_exists?('http://www.prx.org/robots.txt').should be_true
  end

  it "checks http resource exists, follow redirect" do
    Utils.http_resource_exists?('http://prx.org/robots.txt').should be_true
  end

  it "checks http resource doesn't exist" do
    Utils.http_resource_exists?('http://www.prx.org/noway.txt', 1).should be_false
  end

  it "checks http resource and retries" do
    Utils.http_resource_exists?('http://www.prx.org/noway.txt', 2).should be_false
  end

  it "checks for when a url is for an audio file" do
    base = 'http://prx.org/file.'
    Utils::AUDIO_EXTENSIONS.each do |ext|
      Utils.is_audio_file?(base+ext).should be_true
    end
  end

  it "checks for when a url is NOT for an audio file" do
    base = 'http://prx.org/file.'
    ['mov', 'doc', 'txt', 'html'].each do |ext|
      Utils.is_audio_file?(base+ext).should_not be_true
    end
  end

end
