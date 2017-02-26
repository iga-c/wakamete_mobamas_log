require 'twitter'
require 'yaml'
require 'mechanize'

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

# 過去の記録ページのURLを生成する
def wakamete_kako_url(log_number)
  "http://jinrou.dip.jp/~jinrou/kako/#{log_number}.html"
end

# 一日目の夜のtrタグを全列挙する
def parse_first_night_tr(page)
  page.search('//table[@cellpadding="0"]//tr')
      .drop_while{|tr| !tr.text.include?("2日目の朝となりました。")}
      .reverse
      .drop_while{|tr| !tr.text.include?("１日目の夜となりました。")}
      .reverse
end

def parse_village(page, url)
  village_name = page.search('//font')
      .select{|font| font.text.include?("【モバマス】") }
      .first
      .text
      .slice(2..(-3))

  # 死神手帳チェック
  first_night_tr = parse_first_night_tr(page)
  if first_night_tr.any?{|tr| tr.text.start_with?("◆ゲームマスター") && tr.text.include?("【死神手帳】") }
    village_name += "&color(Maroon){(死神手帳)};"
  end

  # デビトリチェック
  if first_night_tr.any?{|tr| tr.text.start_with?("◆ゲームマスター") && tr.text.include?("【デビトリ】") }
    village_name += "&color(Maroon){(デビルトリガー)};"
  end

  # 探偵チェック
  if first_night_tr.any?{|tr| tr.text.start_with?("◆ゲームマスター") && tr.text.include?("探偵役") }
    village_name += "&color(Blue){(探偵)};"
  end

  "[[#{village_name}>#{url}]]"
end

def parse_number_of_people(page)
  tr_text = page.search('//tr').select{|tr| /◆ 村人たち \[生存中 \d+人・死亡 \d+人\]/ === tr.text }.first.text
  match_text = tr_text.scan(/\d+/)

  match_text.map{|num| num.to_i}.inject(:+)
end

def role_count(text, role)
  match_text = text.match(/#{role}(\d+)/)
  match_text[1]
end

def parse_roles(page)
  first_night_tr = parse_first_night_tr(page)
  role_text = first_night_tr[-2].text

  # 狂信
  is_powerup_mud = first_night_tr.any?{|tr| tr.text.start_with?("◆ゲームマスター") && tr.text.include?("狂人") && tr.text.include?("乱数表")}

  # 霊力
  is_powerup_fox = first_night_tr.any?{|tr| tr.text.start_with?("◆ゲームマスター") && tr.text.include?("狐へ")}

  # 背徳
  is_immoralist = first_night_tr.any?{|tr| tr.text.start_with?("◆ゲームマスター") && tr.text.include?("背徳者へ")}


  parse_text = ""

  fortune = role_count(role_text, "占い師")
  parse_text += "占#{(fortune == "1" ? "" : fortune)}/" unless fortune.to_i.zero?

  medium = role_count(role_text, "霊能者")
  parse_text += "霊#{medium == "1" ? "" : medium}/" unless medium.to_i.zero?

  hunter = role_count(role_text, "狩人")
  parse_text += "狩#{hunter == "1" ? "" : hunter}/" unless hunter.to_i.zero?

  joint_owner = role_count(role_text, "共有者")
  parse_text += "共#{joint_owner == "1" ? "" : joint_owner}/" unless joint_owner.to_i.zero?

  if role_text.include?("猫又")
    cat = role_count(role_text, "猫又")
    parse_text += "&color(pink,){猫#{cat == "1" ? "" : cat}};/" unless cat.to_i.zero?
  end

  normal_human = role_count(role_text, "村人")
  normal_human = normal_human.to_i - 1 if is_immoralist
  parse_text += "村#{normal_human}/"

  mud = role_count(role_text, "狂人")
  if is_powerup_mud
    parse_text += "&color(blueviolet,){狂信};/"
  elsif 0 < mud.to_i
    parse_text += "狂#{mud == "1" ? "" : mud}/"
  end

  warewolf = role_count(role_text, "狼")
  parse_text += "&color(#FF0000,){狼#{warewolf}};/"

  fox = role_count(role_text, "妖狐")
  unless fox.to_i.zero?
    parse_text += "&color(#FFA500,){狐#{fox == "1" ? "" : fox}};#{is_powerup_fox ? "(霊力)" : ""}/"
  end

  parse_text += "&color(orange,){背徳};/" if is_immoralist
  parse_text.slice(0..(-2))
end

def parse_end_date(page)
  page.search("//form/table/tr[5]/td/font[2]").first.text
end

def parse_winner(page)
  td_list = page.search("//td")
  return "村人" if td_list.any?{|td| td.text == "人狼の血を根絶することに成功しました！" }
  return "村人" if td_list.any?{|td| td.text == "人狼の血を根絶することに成功し、猫又は村を去って行った。" }
  return "&color(#FF0000,){人狼};" if td_list.any?{|td| td.text == "最後の一人を食い殺すと人狼達は次の獲物を求めて村を後にした・・・。" }
  return "&color(#FFA500,){妖狐};" if td_list.any?{|td| td.text == "人狼がいなくなった今、我の敵などもういない。" }

  "&color(#32CD32,){引分};"
end

def parse_first_role(page)
  table_td = page.search('//table[@class="CLSTABLE"]//td')
  target_td = table_td.select{|td| td.text.include?("初日犠牲者") }.first
  return "村人" if target_td.text.include?("村　人")
  return "&color(#008000,){共有};" if target_td.text.include?("共有者")
  return "&color(#008000,){狩人};" if target_td.text.include?("狩　人")
  return "&color(#008000,){占い};" if target_td.text.include?("占い師")
  return "&color(#008000,){霊能};" if target_td.text.include?("霊能者")
  if target_td.text.include?("狂　人")
    first_night_tr = parse_first_night_tr(page)
    is_mud = first_night_tr.any?{|tr| tr.text.start_with?("◆ゲームマスター") && tr.text.include?("狂人") && tr.text.include?("乱数表")}
    return "&color(blueviolet,){狂信};" if is_mud
  end

  "&color(#FF0000,){狂人};"
end

def parse_sudden_death(page)
  page.search('//table[@cellpadding="0"]//tr')
      .select{|tr| tr.text.include?("突然死しました・・・。【ペナルティ】")}
      .length
end

def crawlparse_kako_page(log_number)
  url = wakamete_kako_url(log_number)
  agent = mechanize_instance
  page = agent.get(url)

  return "" if page.search("//td").any?{|td| td.text.include?("廃村となりました。")}

  village_text = parse_village(page, url)
  people_text = "#{parse_number_of_people(page)}人"
  role_text = parse_roles(page)
  end_date = "#{parse_end_date(page)}日"
  winner =  parse_winner(page)
  first_role = parse_first_role(page)
  sudden_death_count = parse_sudden_death(page)
  sudden_death_text = sudden_death_count == 0 ? "なし" : sudden_death_count

  "|#{log_number}|#{village_text}|#{people_text}|#{role_text}|#{end_date}|#{winner}|#{first_role}|#{sudden_death_text}|"
end

def twitter_client_instance(consumer_key, consumer_secret, access_token, access_token_secret)
  Twitter::REST::Client.new do |config|
    config.consumer_key = consumer_key
    config.consumer_secret = consumer_secret
    config.access_token = access_token
    config.access_token_secret = access_token_secret
  end
end

if __FILE__ == $PROGRAM_NAME
  unless File.exist?("data.yml")
    print("data.ymlファイルが存在しません。init.rbを実行して生成してください。\n")
    exit
  end

  config = YAML.load_file("data.yml")
  client = twitter_client_instance(config[:consumer_key], config[:consumer_secret],
                                   config[:access_token], config[:access_secret])
  print("--- 新規データの確認 ---\n")
  agent = Mechanize.new
  agent.user_agent_alias = "Windows Chrome"
  log_numbers = crawlparse_logs_page(config[:last_log])
  if log_numbers.empty?
    print("新しく建てられた村はありません。\n")
    exit
  end

  print("#{log_numbers.length}件の新しい村が建てられています。\n")
  last_log_number = config[:last_log]
  log_numbers.each do |log_number|
    sleep 5
    send_text = crawlparse_kako_page(log_number)
    next if send_text == ""
    print("#{send_text}\n")
    STDOUT.flush
    last_log_number = [last_log_number, log_number].max
    client.create_direct_message('iga_xx_pri', send_text)
  end
  config[:last_log] = last_log_number

  open("./data.yml", "w") do |f|
    YAML.dump(config, f)
  end
end