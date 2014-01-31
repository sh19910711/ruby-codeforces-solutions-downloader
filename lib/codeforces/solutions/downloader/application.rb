require 'optparse'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'fileutils'

module Codeforces
  module Solutions
    module Downloader
      class Application
        public
        attr_accessor :option

        def initialize
          @option = {
            :page_offset => 1,
            :page_limit => 5,
            :page_limit_specified => false,
            :output_directory => 'dist',
          }
        end

        # parse options
        # @param [Array] argv array of command options
        # @return [nil]
        def parse_options(argv)
          OptionParser.new do |option_parser|
            option_parser.version = Codeforces::Solutions::Downloader::VERSION
            # user_id
            option_parser.on('-u user-id', '--user-id user-id', 'specify codeforces user id', String) {|user_id|
              @option[:user_id] = user_id
            }
            # page offset
            option_parser.on('-o page-offset', '--page-offset page-offset', 'specify page offset (default = 0)', Integer) {|page_offset|
              @option[:page_offset] = page_offset
            }
            # page limit
            option_parser.on('-l page-limit', '--page-limit page-limit', 'specify max page number (default = 5)', Integer) {|page_limit|
              @option[:page_limit] = page_limit
              @option[:page_limit_specified] = true
            }
            # directory
            option_parser.on('-d directory', '--output-directory directory', 'specify output directory (default = dist)', String) {|output_directory|
              @option[:output_directory] = output_directory
            }
            option_parser.parse! argv
          end
          if @option[:user_id].nil?
            abort "Error: user id must be specified"
          end
          nil
        end

        # get submissions data from codeforces.com
        # @return [Array] list of submissions
        def fetch_submissions
          puts "pending..."

          @page_limit = @option[:page_limit]
          @page_limit = [@page_limit, get_page_limit() - @option[:page_offset] + 1].min

          puts "get submission list"
          puts "    page_limit = #{@page_limit}"
          puts "    page_offset = #{@option[:page_offset]}"
          puts "    output_directory = #{@option[:output_directory]}"

          submissions = get_submissions()

          len = submissions.length
          cnt = 0
          submissions.each {|s|
            info     = fetch_submission s[:contest_id], s[:submission_id]
            ext      = resolve_language(info[:language])
            filename = "#{@option[:output_directory]}/#{s[:submission_id]}.#{ext}"

            FileUtils.mkdir_p "#{@option[:output_directory]}"
            File.open(filename, 'w') {|f| f.write info[:source] }

            cnt += 1
            puts "save: #{filename} [#{cnt}/#{len}]"
          }
        end

        def fetch_submission(contest_id, submission_id)
          url = "http://codeforces.com/contest/#{contest_id}/submission/#{submission_id}"
          puts "fetch: #{url}"
          sleep 5
          body = get_body(url)
          doc = Nokogiri::HTML body
          {
            :source => doc.xpath('id("content")').search('//pre[contains(concat(" ",@class," ")," prettyprint ")]').text.strip,
            :language => doc.xpath('//table//tr')[1].search('//td')[3].text.strip,
          }
        end

        private
        def get_page_limit
          url = "http://codeforces.com/submissions/#{@option[:user_id]}/page/1"
          body = get_body(url)
          doc = Nokogiri::HTML body
          items = doc.xpath('//div[contains(concat(" ",@class," ")," pagination ")]//span[contains(concat(" ",@class," ")," page-index ")]').search('a')
          # example: /submissions/sh19910711/page/35
          items.map {|item| /[0-9]+$/.match(item.attributes["href"].value)[0].to_i }.max
        end

        def get_submissions()
          page_start = @option[:page_offset]
          page_end = page_start + @page_limit - 1
          submissions = (page_start..page_end).map do |page_id|
            url = "http://codeforces.com/submissions/#{@option[:user_id]}/page/#{page_id}"
            puts "fetch: #{url} [#{page_id - page_start + 1}/#{page_end - page_start + 1}]"
            sleep 5
            body = get_body(url)
            doc = Nokogiri::HTML body
            items = doc.xpath('//table[contains(concat(" ",@class," ")," status-frame-datatable ")]').search('tr[@data-submission-id]')
            res = items.map {|item|
              td_list = item.search('td')
              {
                :submission_id => td_list[0].text.strip,
                :contest_id => /\/problemset\/problem\/([0-9]+)/.match(td_list[3].search('a')[0].attributes['href'].value.strip)[1]
              }
            }
          end
          submissions.flatten
        end

        def get_body(url)
          Net::HTTP.get URI.parse(url)
        end

        # return file extension
        def resolve_language(language_text)
          case language_text
          when "GNU C"
            "c" 
          when "GNU C++"
            "cpp" 
          when "GNU C++0x"
            "cpp" 
          when "MS C++"
            "cpp" 
          when "Mono C#"
            "cs" 
          when "MS C#"
            "cs" 
          when "D"
            "d" 
          when "Go"
            "go" 
          when "Haskell"
            "hs" 
          when "Java 6"
            "java" 
          when "Java 7"
            "java" 
          when "Ocaml"
            "ml" 
          when "Delphi"
            "pas" 
          when "FPC"
            "pas" 
          when "Perl"
            "pl" 
          when "PHP"
            "php" 
          when "Python 2"
            "py" 
          when "Python 3"
            "py" 
          when "Ruby"
            "rb" 
          end
        end
      end
    end
  end
end

