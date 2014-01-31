require 'spec_helper'

describe "Application" do
  before do
    @app = Codeforces::Solutions::Downloader::Application.new
    @app.option[:user_id] = "sh19910711"
    @app.stub(:sleep).and_return(0)
  end

  before do
    FakeFS.deactivate!
    @dummy_submissions_respoinse = SpecHelpers.read_file(File.join('mock', 'codeforces', 'submissions', 'sh19910711.html'))
    @dummy_submissions_respoinse_second = SpecHelpers.read_file(File.join('mock', 'codeforces', 'submissions', 'sh19910711_2.html'))
    @dummy_submission_999999999_respopnse = SpecHelpers.read_file(File.join('mock', 'codeforces', 'submission', '999999999.html'))
    FakeFS.activate!
  end

  context "#get_submissions" do
    before do
      # page any
      WebMock.stub_request(:get, /^http:\/\/codeforces.com\/submissions\/sh19910711\/page\/[0-9]*$/)
        .to_return(:status => 200, :body => @dummy_submissions_respoinse_second)

      # page 1
      WebMock.stub_request(:get, /^http:\/\/codeforces.com\/submissions\/sh19910711\/page\/1$/)
        .to_return(:status => 200, :body => @dummy_submissions_respoinse)
    end

    before do
      @app.instance_variable_set :@page_limit, 7
    end

    context "return value submission id" do
      subject { SpecHelpers.ignore_stdout { @app.send(:get_submissions) }.map {|submission| submission[:submission_id]} }

      it "should return 7 * 50 elements" do
        subject.length.should eq 7 * 50
      end

      it "should contain submission id" do
        # first
        subject.should include "5828986"
        subject.should include "5828956"
        subject.should include "5857785"
        # second
        subject.should include "999999999"
      end
    end

    context "return value contest id" do
      subject { SpecHelpers.ignore_stdout { @app.send(:get_submissions) }.map {|submission| submission[:contest_id]} }

      it "should contain contest id" do
        subject.should include "387"
        subject.should include "149"
        subject.should include "146"
      end
    end

    context "output" do
      subject { SpecHelpers.capture_stdout { @app.send(:get_submissions) } }
      it "should have 7 URLs" do
        (1..7).each {|page_id|
          subject.should match "http://codeforces.com/submissions/sh19910711/page/#{page_id}"
        }
      end
    end
  end

  context "#get_page_limit" do
    before do
      @app.instance_variable_set :@last_body, @dummy_submissions_respoinse
    end

    subject { @app.send(:get_page_limit) }

    it "should return 35" do
      should eq 35
    end
  end

  context "#fetch_submission" do
    before do
      WebMock.stub_request(:get, /http:\/\/codeforces.com\/contest\/165\/submission\/999999999/)
        .to_return(:body => @dummy_submission_999999999_respopnse)
    end

    subject { SpecHelpers.ignore_stdout { @app.fetch_submission "165", "999999999" } }

    it "code" do
      subject[:source].should eq "this is test"
      subject[:language].should eq "GNU C++0x"
    end
  end

  context "#resolve_language" do
    it { @app.send(:resolve_language, "GNU C").should eq "c" }
    it { @app.send(:resolve_language, "GNU C++").should eq "cpp" }
    it { @app.send(:resolve_language, "GNU C++0x").should eq "cpp" }
    it { @app.send(:resolve_language, "MS C++").should eq "cpp" }
    it { @app.send(:resolve_language, "Mono C#").should eq "cs" }
    it { @app.send(:resolve_language, "MS C#").should eq "cs" }
    it { @app.send(:resolve_language, "D").should eq "d" }
    it { @app.send(:resolve_language, "Go").should eq "go" }
    it { @app.send(:resolve_language, "Haskell").should eq "hs" }
    it { @app.send(:resolve_language, "Java 6").should eq "java" }
    it { @app.send(:resolve_language, "Java 7").should eq "java" }
    it { @app.send(:resolve_language, "Ocaml").should eq "ml" }
    it { @app.send(:resolve_language, "Delphi").should eq "pas" }
    it { @app.send(:resolve_language, "FPC").should eq "pas" }
    it { @app.send(:resolve_language, "Perl").should eq "pl" }
    it { @app.send(:resolve_language, "PHP").should eq "php" }
    it { @app.send(:resolve_language, "Python 2").should eq "py" }
    it { @app.send(:resolve_language, "Python 3").should eq "py" }
    it { @app.send(:resolve_language, "Ruby").should eq "rb" }
  end
end

