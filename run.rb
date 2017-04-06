require 'yaml'
require 'mechanize'
require 'selenium-webdriver'
require_relative 'mobamas_parser'

def mechanize_instance
  agent = Mechanize.new
  agent.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:50.0) Gecko/20100101 Firefox/50.0"

  agent
end

# わかめて過去ログ一覧ページのURLを生成する
def wakamete_logs_url(last_log)
  start_number = last_log - 15500 # 15123のズレがあるけど余裕を見て15500に。
  "http://jinrou.dip.jp/~jinrou/jinrokakoview.cgi?s=#{start_number}&n=1000"
end

# クロール対象のモバマス村の番地一覧を生成する
def crawlparse_logs_page(last_log)
  url = wakamete_logs_url(last_log)
  agent = mechanize_instance
  page = agent.get(url)
  page.search('//a').select{|a| a.text.include?("【モバマス】") }
    .map{|a| a.attribute("href").text }
    .map{|href| href.delete("^0-9") }
    .map{|num| num.to_i }
    .select{|num| last_log < num }
end

if __FILE__ == $PROGRAM_NAME
  unless File.exist?("data.yml")
    print("data.ymlファイルが存在しません。init.rbを実行して生成してください。\n")
    exit
  end

  config = YAML.load_file("data.yml")
  print("--- 新規データの確認 ---\n")
  agent = Mechanize.new
  agent.user_agent_alias = "Windows Chrome"
  log_numbers = crawlparse_logs_page(config[:last_log])
  if log_numbers.empty?
    print("新しく建てられた村はありません。\n")
    exit
  end

  driver = Selenium::WebDriver.for :phantomjs
  driver.navigate.to "http://wikiwiki.jp/cinderejinro/?cmd=edit&page=%B2%E1%B5%EE%A5%ED%A5%B0%A1%A12017%C7%AF"
  sleep 30

  print("#{log_numbers.length}件の新しい村が建てられています。\n")
  last_log_number = config[:last_log]
  log_numbers.sort.each do |log_number|
    sleep 5
    mobamas_log = MobamasParser.new(log_number)
    driver.find_element(name: "msg").send_keys("#{mobamas_log.generate_wiki_text}\n")
    last_log_number = [last_log_number, log_number].max
  end

  driver.find_element(name: "write").click
  config[:last_log] = last_log_number

  open("./data.yml", "w") do |f|
    YAML.dump(config, f)
  end
end