# -*- coding: utf-8 -*-
require 'mini_magick' # image manipulation
require 'rtesseract'  # OCR
require 'hpricot' #html analyzer

require 'net/http'
require 'yaml'
class Frigga
  CAPTCHA_FILE = "captcha.jpg"
  URL = 'http://222.30.32.10/'
  VC_URL = URL+'ValidateCode' # CAPTCHA_URL
  LOGIN_URL = URL+'stdloginAction.do'

  FORM_operation = 'no'.freeze
  FORM_submittype = '%C8%B7+%C8%CF'.freeze
  
  def self.get_utf8_body(resp)
    body = resp.body
    doc = Hpricot(body)
    encoding = doc.search("meta[@content]").first.attributes['content'].split('charset=')[1]
    body.force_encoding(encoding).encode("UTF-8")
  end
  
  def initialize
    @cookie = ""
    @captcha = ""
  end

  def login(id, pwd)
    get_cookie

    get_captha_text

    uri = URI(LOGIN_URL)  
    http = Net::HTTP.start(uri.host, uri.port)
    data = gen_form_data({
      operation:        FORM_operation,
      usercode_text:    id,
      userpwd_text:     pwd,
      checkcode_text:   @captcha,
      submittype:       FORM_submittype
    })
    headers = {'Cookie' => @cookie}

    #response
    http.post(uri.request_uri, data, headers)
  end

protected

  def gen_form_data(list)
    data = ""
    list.each do |key, val|
      data<<"#{key}=#{val}"<<'&'
    end
    data.chop
  end

  def get_captha_text
    uri = URI.parse(VC_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request.initialize_http_header({ "Cookie" => @cookie })
    response = http.request(request)
    img = File.open(CAPTCHA_FILE, 'w')
    img.write(response.read_body)
    img.close
    img = MiniMagick::Image.new(CAPTCHA_FILE)
    img.resize(200)

    @captcha = RTesseract.new(img.path).to_s_without_spaces
  end

  def get_cookie
    uri = URI.parse(URL)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    @cookie = response.get_fields('set-cookie')[0].split(';')[0]
  end
end

=begin
user.yml
---
:id: 'yourid'
:pwd: yourpassword
=end
f = File.open('user.yml','r')
data = f.read
user = YAML.load(data)

resp = Frigga.new.login(user[:id], user[:pwd])

print Frigga::get_utf8_body resp
