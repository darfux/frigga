# -*- coding: utf-8 -*-
require 'mini_magick' # image manipulation
require 'rtesseract'  # OCR

require 'net/http'
require 'yaml'

CAPTCHA_FILE = "captcha.jpg"
URL = 'http://222.30.32.10/'
VC_URL = URL+'ValidateCode' # CAPTCHA_URL
LOGIN_URL = URL+'stdloginAction.do'

# user.yml
#   id: 111XXXX
#   pwd: ********
f = File.open('user.yml','r')
data = f.read
user = YAML.load(data)

usercode = user[:id]
userpwd = user[:pwd]

# login
uri = URI.parse(URL)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)

cookie = response.get_fields('set-cookie')[0].split(';')[0]

# get CAPTCHA
uri = URI.parse(VC_URL)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)
request.initialize_http_header({ "Cookie" => cookie })
response = http.request(request)
img = File.open(CAPTCHA_FILE, 'w')
img.write(response.read_body)
img.close
img = MiniMagick::Image.new(CAPTCHA_FILE)
img.resize(200)

# checkcode = RTesseract.new(img.path).to_s_without_spaces
checkcode = gets

uri = URI.parse(LOGIN_URL)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri.request_uri)
request.set_form_data({
                        operation:'no',
                        usercode_text: usercode,
                        userpwd_text: userpwd,
                        checkcode_text: checkcode,
                        submittype:'%C8%B7+%C8%CF'
                      })
request.initialize_http_header({ "Cookie" => cookie })
response = http.request(request)

body = response.body

# 从body中找到charset="XXX"
charset_begin = body.index("charset=")+9
charset_end = body.index("\"", charset_begin)
body_encoding = body[charset_begin, charset_end-charset_begin]

body = response.body.force_encoding(body_encoding).encode("UTF-8")

if body.empty?
  puts "success"
else
  puts "wrong#{checkcode}"
  exit
end
