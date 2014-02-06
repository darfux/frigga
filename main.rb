require 'mini_magick'
require 'rtesseract'

require 'net/http'
require 'yaml'

TMP_NAME = "tmp.jpg"
URL = 'http://222.30.32.10/'
VC_URL = URL+'ValidateCode'
LOGIN_URL = URL+'stdloginAction.do'


f = File.open('user.yml','r')
data = f.read
user = YAML.load(data)

usercode = user[:id]
userpwd = user[:pwd]

uri = URI.parse(URL)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)

cookie = response.get_fields('set-cookie')[0].split(';')[0]

# loop do
uri = URI.parse(VC_URL)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)
request.initialize_http_header({
    "Cookie" => cookie
  })
response = http.request(request)
img = File.open(TMP_NAME, 'w')
img.write(response.read_body)
img.close
img = MiniMagick::Image.new(TMP_NAME)
# img.colorspace("GRAY")
img.resize(200)
# p img.path
checkcode = RTesseract.new(img.path).to_s_without_spaces

# p checkcode
# File.unlink(img.path)

# p checkcode,cookie

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
request.initialize_http_header({
    "Cookie" => cookie
  })
response = http.request(request)

body = response.body.force_encoding("gb2312").encode("UTF-8")

if body.empty?
  puts "success"
else
  puts "wrong#{checkcode}"
  exit
end
# end
