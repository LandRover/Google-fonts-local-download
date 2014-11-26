#!/usr/bin/ruby -w

require 'net/http'
require 'pp'

$output_file = 'fonts.css'
$zip = false

## List of fonts to download from google.
fonts = [];

## Google fonts paths
google = {
    'domain' => 'fonts.googleapis.com',
    'path' => '/css?family='
}

def usage(s)
    $stderr.puts(s)
    $stderr.puts("Usage: #{File.basename($0)}: <-f FontName:300,400,700> [-f FontName:300,400,700] [-o style.css] [-z]")
    exit(2)
end

loop { case ARGV[0]
    when '-f' then  ARGV.shift; fonts.push(ARGV.shift)
    when '-o' then  ARGV.shift; $output_file = ARGV.shift
    when '-z' then  ARGV.shift; $zip = true
    when /^-/ then  usage("Unknown option: #{ARGV[0].inspect}")
    else break
end; }


class CSS
    @tmp = './tmp_fonts' ## tmp dir to store fonts
    @fonts = [] ## fonts list to download
    @url = {} ## fonts path.. usually meant for google but sent as constructor args

    def initialize(params = {})
        @fonts = params.fetch(:fonts, [])
        @url = params.fetch(:url, {})
    end

    def load
        @fonts.each do |font|
            raw_css = {};
            getTypes().each do |type, prop|
                stylesheet = getStyle(font, type)
                font_details = parseCss(stylesheet, type)
                raw_css[type] = {
                    'raw' => stylesheet
                }

                pp font_details
            end

            puts raw_css
        end

        puts 'loading'
    end


    private
        ##
        def parseCss(stylesheet, type)
            fonts = {} ## parsed fonts data
            stylesheet.split('@font-face').drop(1).each do |font|
                family, style, weight = font.scan(/.*font-(weight|style|family): (.*?);/)
                src = font.scan(/.*url\((.*?)\) format/)
                family = family.pop.gsub("'", '')
                weight = weight.pop
                style = style.pop

                fonts["#{family}#{weight}"] = {
                    'font-family' => family,
                    'font-style' => style,
                    'font-weight' => weight,
                    'src' => {
                        type => src
                    }
                }
            end

            return fonts
        end


        ## Creates HTTP request and returns CSS string for that user-agent.
        def getStyle(font, type)
            log('info', "Downloading CSS for font: #{font} and Type: #{type}")

            http = Net::HTTP.new(@url['domain'])
            req = Net::HTTP::Get.new(@url['path'] + font, {
                'User-Agent' => getTypes()[type]['useragent']
            })
            response = http.request(req)

            return response.body
        end

        ## Types and useragents mapping
        def getTypes
            return {
                'eot' => {
                    'useragent' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; Trident/4.0; .NET CLR 1.1.4322; .NET4.0C; .NET4.0E; .NET CLR 2.0.50727)',
                    'format' => 'eot'
                },
                'ttf' => {
                    'useragent' => 'Mozilla/5.0 (Linux; U; Android 2.3.4; en-us; Nexus S Build/GRJ22) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1',
                    'format' => 'truetype'
                },
                'woff' => {
                    'useragent' => 'Mozilla/5.0 (Windows NT 5.2; rv:33.0) Gecko/20100101 Firefox/33.0',
                    'format' => 'woff'
                },
                'woff2' => {
                    'useragent' => 'Mozilla/5.0 (Windows NT 5.2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36',
                    'format' => 'woff2'
                }
            }
        end

        ## Genric way to print verbose
        def log(lvl, text)
            puts "[#{lvl}]: #{text}"
        end

        ## Deep merge 2 hashes
        def deep_merge(p)
            m = proc { |key,v,vv| v.class == Hash && vv.class == Hash ? v.merge(vv, &m) : vv }
            merge(p, &m)
        end
end

css = CSS.new(:fonts => fonts, :url => google)
css.load()
