# -*- coding: utf-8 -*-
$LOAD_PATH.unshift(File.dirname(__FILE__))  #add current dir to load path

require 'frigga'
require 'yaml'
=begin
user.yml
---
:id: 'yourid'
:pwd: yourpassword
=end
f = File.open('user.yml','r')
data = f.read
user = YAML.load(data)

fr = Frigga.new
body = fr.login(user[:id], user[:pwd])
print fr
# print body
