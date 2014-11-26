#!/usr/bin/ruby -w

require 'net/http'
require 'fileutils'
require 'pp'

$output = 'fonts.css'
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

## Deep merge 2 hashes
public
def deep_merge(p)
    m = proc { |key,v,vv| v.class == Hash && vv.class == Hash ? v.merge(vv, &m) : vv }
    merge(p, &m)
end

class CSS
    @tmp = '' ## tmp dir to store fonts
    @template = '' ## css file template
    @output = '' ## output.css
    @fonts = [] ## fonts list to download
    @url = {} ## fonts path.. usually meant for google but sent as constructor args

    def initialize(params = {})
        @fonts = params.fetch(:fonts, [])
        @url = params.fetch(:url, {})
        @template = params.fetch(:template, 'stylesheet.tpl')
        @tmp = params.fetch(:tmp, './tmp_fonts')
        @output = params.fetch(:output, 'fonts.css')
    end


    def load
        @fonts.each do |font|
            f = {} ## font and all weights stored here

            getTypes().each do |ext, prop|
                stylesheet = getStyle(font, ext)
                font_details = parseCss(stylesheet, ext)
                f = f.deep_merge(font_details)
            end

            save(@tmp + '/' + @output, get_font_stylesheet(f))
        end

        puts 'loading'
    end


    private
        def download_all_fonts(font_file, fonts_list)
            directory_exists?(File.dirname(font_file))
            fonts_list.each do |ext, url|

                uri = URI.parse(url)
                Net::HTTP.start(uri.host, uri.port) do |http|
                    resp = http.get(uri.to_s)

                    open(font_file + '.' + ext, 'wb') do |file|
                        file.write(resp.body)
                    end
                end
            end

            puts font_file
            puts fonts_list
        end

        def get_font_stylesheet(font)
            css_text = ''
            ## iterate combines fonts and weights (fw var is font_weight shorter :P)
            font.each do |fw, style|
               css_tpl = getTemplate
               font_name = name_to_dir(style['font-family'])
               font_file = 'fonts/' + font_name + '/' + font_name + '_' + style['font-weight']

               {
                   '{FONT_NAME}' => style['font-family'],
                   '{FONT_FILE}' => font_file,
                   '{FONT_WEIGHT}' => style['font-weight'],
                   '{FONT_STYLE}' => style['font-style'],
                   '{DATE}' => Time.now.inspect
               }.each { |k, v| css_tpl.gsub!(k, v) }

               css_text += css_tpl + "\n\n"

               download_all_fonts(@tmp + '/' + font_file, style['src'])
            end

            return css_text
        end


        ## Extract font-face data from css string
        def parseCss(stylesheet, ext)
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
                        ext => src.pop.pop
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


        def getTemplate
            return IO.read(@template)
        end


        ## converts upper case and chars to uniform string
        def name_to_dir(name)
            {
                '+' => '_',
                ' ' => '_'
            }.each { |k, v| name.gsub!(k, v) }

            return name.downcase
        end


        def save(file, content)
            directory_exists?(File.dirname(file))

            return File.write(file, content)
        end


        def directory_exists?(directory_name)
            FileUtils.mkdir_p(directory_name) unless File.exists?(directory_name)

            return File.directory?(directory_name)
        end


        ## Genric way to print verbose
        def log(lvl, text)
            puts "[#{lvl}]: #{text}"
        end
end

css = CSS.new(:fonts => fonts, :url => google, :output => $output)
css.load()
