require 'oauth'
require 'oauth/consumer'
require 'optparse'
require 'yaml'

def options
  option = {}
  OptionParser.new do |opt|
    opt.on('--consumer-key VALUE',         'Twitter APIのConsumer Key(必須)')        {|v| option[:consumer_key] = v }
    opt.on('--consumer-secret VALUE',      'Twitter APIのConsumer Key Secret(必須)') {|v| option[:consumer_secret] = v }
    opt.on('--access-token VALUE',         'Twitter APIのAccess Token')              {|v| option[:access_token] = v }
    opt.on('--access-token-secret VALUE',  'Twitter APIのAccess Token Secret')       {|v| option[:access_secret] = v }
    opt.on('--last-log VALUE',             '最後に追加されたログの番地(必須)')       {|v| option[:last_log] = v }

    opt.parse!(ARGV)
  end

  option
end

def create_request_token(consumer_key, consumer_secret)
  consumer = OAuth::Consumer.new(consumer_key, consumer_secret, { :site => "https://api.twitter.com" })
  consumer.get_request_token
rescue => e
  print("Consumer KeyかConsumer Secretが不正です。\n")
  print(e)
  exit
end

def create_access_token(request_token)
  print("下記のURLのアプリ連携を行ってください。\n")
  print("#{request_token.authorize_url}\n")
  print("\n")
  print("アプリ連携後に表示されるPIN CODEを入力してください：")
  STDOUT.flush
  pin = gets.to_i
  access_token = request_token.get_access_token(:oauth_verifier => "#{pin}")
  [access_token.token, access_token.secret]
rescue => e
  print("アプリ連携時にエラーが発生しました。再度やり直してください。\n")
  print(e)
  exit
end

if __FILE__ == $PROGRAM_NAME
  option = options
  if option[:consumer_key].nil? || option[:consumer_secret].nil? || option[:last_log].nil?
    print("Consumer KeyとConsumer Secretと最後に追加されたログの番地を実行時に与えてください。\n")
    exit
  end

  access_token = option[:access_token]
  access_secret = option[:access_secret]
  if access_token.nil? || access_secret.nil?
    request_token = create_request_token(option[:consumer_key], option[:consumer_secret])
    access_token, access_secret = create_access_token(request_token)
  end

  create_yml_hash = {
      consumer_key: option[:consumer_key],
      consumer_secret: option[:consumer_secret],
      access_token: access_token,
      access_secret: access_secret,
      last_log: option[:last_log].to_i
  }

  open("./data.yml", "w") do |f|
    YAML.dump(create_yml_hash, f)
  end
end