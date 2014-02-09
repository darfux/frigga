# -*- coding: utf-8 -*-
require 'mini_magick' # image manipulation
require 'rtesseract'  # OCR
require 'hpricot' #html analyzer

require 'net/http'
require 'yaml'
class Frigga
  :READY
  :SUCCESS
  :FAIL
  :CAPTCHA_WRONG
  :USER_INFO_WRONG
  def initialize(doretry=true)
    @cookie = ""
    @captcha = ""
    @user = {id:nil, pwd:nil}
    @retry = doretry
    @retrycounter = 8
    @status = {stat: :READY, info:nil}
  end

  def login(id, pwd)
    @user[:id] = id
    @user[:pwd] = pwd

    get_cookie

    loop do
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

      resp = http.post(uri.request_uri, data, headers)
      body = Frigga::get_utf8_body(resp)
      doc = Hpricot(body)
      fail = doc.search('noframes').first.nil?
      if fail
        info = doc.search('li').first
        if info.nil?
          raise 'Unknown wrong.'
        end

        content = info.inner_html
        print content,@captcha
        if content.match(CONFIRM_captcha)
          @status[:stat] = :FAIL
          @status[:info] = :CAPTCHA_WRONG
          break unless @retry && @retrycounter>0
          @retrycounter-=1
          puts 'ocr failed,retrying...'
          sleep 2
          redo
        end
        if content.match(CONFIRM_input)
          @status[:stat] = :FAIL
          @status[:info] = :USER_INFO_WRONG
          break
        end

        raise 'Unknown wrong.'
      end
      @status[:stat] = :SUCCESS
      @status[:info] = nil
      break
    end
    return @status[:stat] == :SUCCESS
  end

  def to_s
    org = super
    org.chop<<"\n[user]#{@user};\n[cookie]#{@cookie}\n[status]#{@status}"<<'>'
  end
  
protected
  CAPTCHA_FILE = 'captcha.jpg'
  URL = 'http://222.30.32.10/'
  VC_URL = URL+'ValidateCode' # CAPTCHA_URL
  LOGIN_URL = URL+'stdloginAction.do'

  FORM_operation = 'no'
  FORM_submittype = '%C8%B7+%C8%CF'
  CONFIRM_captcha = "请输入正确的验证码！"
  CONFIRM_input = "用户不存在或密码错误！"
  def self.get_utf8_body(resp)
    body = resp.body
    doc = Hpricot(body)
    encoding = doc.search("meta[@content]").first.attributes['content'].split('charset=')[1]
    body.force_encoding(encoding).encode("UTF-8")
  end

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
    img.resize(300)
    sleep 1
    # img.monochrome
    # img.sharpen -1

    @captcha = RTesseract.new(img.path).to_s_without_spaces.gsub(/[^0-9]/,"")
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

fr = Frigga.new(false)
body = fr.login(user[:id], user[:pwd])
print fr
# print body
