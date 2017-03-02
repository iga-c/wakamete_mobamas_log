class WakameteParser
  #
  # わかめて過去ログページを元にインスタンスを生成する。
  #
  def initialize(log_number)

  end

  #
  # 特殊村かどうかを判定し返す。
  # "通常", "死神手帳", "デビルトリガー"の内1つの文字列が返される。
  #
  def village_type

  end

  #
  # 村の参加人数を整数で返す。
  #
  def population

  end

  #
  # 役職の人数一覧をハッシュで返す。
  # 例: {"村人" => 5, "人狼" => 2, "占い師" => 1, "霊能者" => 1, "狩人" => 1, "狂人" => 1, "共有者" => 0, "妖狐" => 1}
  #
  def role

  end

  #
  # ゲーム終了日の日数を整数で返す。
  #
  def end_date

  end

  #
  # 勝利陣営を返す。
  # "村人", "人狼", "妖狐"の内1つの文字列が返される。
  #
  def winner_camp

  end

  #
  # 初日犠牲者の役職を返す。
  # "村人" や "占い師"　など。
  #
  def first_death_role

  end

  #
  # 突然死した人数を整数で返す。
  # GMが手動で突然死させた人は人数にカウントしない。
  #
  def sudden_death

  end

  private
  #
  # 該当のログを取得しメンバ変数に保存する。
  # crawlに成功した場合にはtrueを、crawlに失敗したり該当のログが無い場合にはfalseを返す。
  #
  def crawl

  end

  #
  # 過去の記録ページのURLを生成する
  #
  def wakamete_kako_url(log_number)

  end

  #
  # 一日目の夜のtrタグを全列挙する
  #
  def parse_first_night_tr(page)

  end
end