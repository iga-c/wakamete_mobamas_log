require 'mechanize'

class WakameteParser
  attr_accessor :log_number, :page

  #
  # わかめて過去ログページを元にインスタンスを生成する。
  #
  def initialize(log_number)
    @log_number = log_number
    crawl
  end

  #
  # 特殊村かどうかを判定し返す。
  # "通常", "死神手帳", "デビルトリガー"の内1つの文字列が返される。
  #
  def village_type
    tr_array = first_night_tr
    type = "通常"
    if tr_array.any?{|tr| tr.text.start_with?("◆ゲームマスター") && tr.text.include?("【死神手帳】") }
      type = "死神手帳"
    end
    if tr_array.any?{|tr| tr.text.start_with?("◆ゲームマスター") && tr.text.include?("【デビトリ】") }
      type = "デビルトリガー"
    end

    type
  end

  #
  # 村の参加人数を整数で返す。
  #
  def population
    tr_text = @page.search('//tr').select{|tr| /◆ 村人たち \[生存中 \d+人・死亡 \d+人\]/ === tr.text }.first.text
    match_text = tr_text.scan(/\d+/)

    match_text.map{|num| num.to_i}.inject(:+)
  end

  #
  # 役職の人数一覧をハッシュで返す。
  # 例: {"村人" => 5, "狼" => 2, "占い師" => 1, "霊能者" => 1, "狩人" => 1, "狂人" => 1, "共有者" => 0, "妖狐" => 1}
  #
  def role
    tr_array = first_night_tr
    role_text = tr_array[-2].text
    role_list = ["村人", "狼", "占い師", "霊能者", "狩人", "狂人", "共有者", "妖狐"]
    results_hash = {}

    role_list.select{|r| role_text.include?(r)}
        .each{|r| results_hash[r] = role_count(role_text, r)}

    results_hash
  end

  #
  # ゲーム終了日の日数を整数で返す。
  #
  def end_date
    @page.search("//form/table/tr[5]/td/font[2]").first.text.strip.to_i
  end

  #
  # 勝利陣営を返す。
  # "村人", "人狼", "妖狐", "引分"の内1つの文字列が返される。
  #
  def winner_camp
    td_list = @page.search("//td")
    return "村人" if td_list.any?{|td| td.text == "人狼の血を根絶することに成功しました！" }
    return "村人" if td_list.any?{|td| td.text == "人狼の血を根絶することに成功し、猫又は村を去って行った。" }
    return "人狼" if td_list.any?{|td| td.text == "最後の一人を食い殺すと人狼達は次の獲物を求めて村を後にした・・・。" }
    return "妖狐" if td_list.any?{|td| td.text == "人狼がいなくなった今、我の敵などもういない。" }

    "引分"
  end

  #
  # 初日犠牲者の役職を返す。
  # "村人" や "占い師"　など。
  #
  def first_death_role
    table_td = @page.search('//table[@class="CLSTABLE"]//td')
    target_td = table_td.select{|td| td.text.include?("初日犠牲者") }.first
    return "村人" if target_td.text.include?("村　人")
    return "狩人" if target_td.text.include?("狩　人")
    return "狂人" if target_td.text.include?("狂　人")
    return "占い師" if target_td.text.include?("占い師")
    return "霊能者" if target_td.text.include?("霊能者")

    "共有者"
  end

  #
  # 突然死した人数を整数で返す。
  # GMが手動で突然死させた人は人数にカウントしない。
  #
  def sudden_death
    @page.search('//table[@cellpadding="0"]//tr')
        .select{|tr| tr.text.include?("突然死しました・・・。【ペナルティ】")}
        .length
  end

  private
  #
  # 該当のログを取得しメンバ変数に保存する。
  # crawlに成功した場合にはtrueを、crawlに失敗、該当のログが無い、廃村の場合にはfalseを返す。
  #
  def crawl
    agent = Mechanize.new
    agent.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:50.0) Gecko/20100101 Firefox/50.0"

    url = wakamete_kako_url(@log_number)
    @page = agent.get(url)
    if @page.nil? || @page.search("//td").any?{|td| td.text.include?("廃村となりました。")}
      @page = nil
      return false
    end

    true

  rescue => e
    STDERR.puts(e)
    false
  end

  #
  # 過去の記録ページのURLを生成する
  #
  def wakamete_kako_url(log_number)
    "http://jinrou.dip.jp/~jinrou/kako/#{log_number}.html"
  end

  #
  # 一日目の夜のtrタグを全列挙する
  #
  def first_night_tr
    @page.search('//table[@cellpadding="0"]//tr')
        .drop_while{|tr| !tr.text.include?("2日目の朝となりました。")}
        .reverse.drop_while{|tr| !tr.text.include?("１日目の夜となりました。")}
        .reverse
  end

  #
  # text内に書かれているroleの役職の人数を整数で返す。
  #
  def role_count(text, role)
    match_text = text.match(/#{role}(\d+)/)
    match_text[1].to_i
  end
end