require 'tempfile'
require 'twitter'
require 'optparse'
require 'RMagick'
require 'dotenv'
include Magick

Dotenv.load

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: example.rb [options]"

    opts.on("-t", "--tweet", "Tweet instead of printing") do |t|
        options[:tweet] = true
    end
end.parse!

def image(text)
  image = Image.read('regret-this-template.png').first
  draw = Draw.new

  text_width = 550
  text_height = 50
  text_margin = 125
  text_y = 24
  char_width = 18

  text = text.split(' ').map { |i| i.scan(/[^\s]{1,18}/).join("\n")}.join(' ')
  wrap_text = text.scan(/\S.{0,#{char_width}}\S(?=\s|$)|\S+/).join("\n")

  draw.annotate(image, text_width, text_height, text_margin, text_y, wrap_text) do
    self.font = './vgasys.otf'
    self.pointsize = 14
    self.fill = 'black'
    self.text_antialias = true
    self.stroke_width = 2
    self.font_weight = 100
  end

  file = Tempfile.new('output')
  file.write(image.to_blob)
  file.rewind
  file
end

text = ARGV[0].upcase

rendered = image(text)

if options[:tweet] then
    client = Twitter::REST::Client.new do |config|
      config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
      config.access_token_secret = ENV['TWITTER_OAUTH_SECRET']
    end
    client.update_with_media('', rendered)
else
    `cp #{rendered.path} output.png`
end
