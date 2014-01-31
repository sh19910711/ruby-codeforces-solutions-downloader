require 'fakefs/safe'
require 'fakefs/spec_helpers'
require 'webmock'

WebMock.disable_net_connect!
RSpec.configure do |config|
  config.include FakeFS::SpecHelpers
end

module SpecHelpers
  def self.read_file array_of_path
    File.read get_path(array_of_path)
  end

  def self.get_path array_of_path
    File.expand_path(File.join(File.dirname(__FILE__), File.join(array_of_path)))
  end

  def self.capture_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end

  def self.ignore_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
  end
end

require 'codeforces/solutions/downloader'

