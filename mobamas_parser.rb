require_relative 'wakamete_parser'

class MobamasParser < WakameteParser
  def village_type
    type = super
    tr_array = first_night_tr

    if tr_array.any?{|tr| tr.text.start_with?('◆ゲームマスター') && tr.text.include?('※もし探偵を噛んだ場合は') }
      type = '探偵'
    end

    type
  end

  def role
    result_hash = super
    tr_array = first_night_tr

    if tr_array.any?{|tr| tr.text.start_with?('◆ゲームマスター') && tr.text.include?('狂人の人は乱数表を')}
      result_hash['狂人'] = 0
      result_hash['狂信者'] = 1
    end

    tr_array = first_night_tr
    if tr_array.any?{|tr| tr.text.start_with?('◆ゲームマスター') && tr.text.include?('被った場合は背徳者になれません')}
      result_hash['村人'] -= 1
      result_hash['背徳者'] = 1
    end

    result_hash
  end

  def first_death_role
    result_role = super
    role_hash = role
    tr_array = @page.search('//table[@cellpadding="0"]//tr')

    return '狂信者' if result_role == '狂人' && role_hash.keys.include?('狂信者')
    return '背徳者' if tr_array.any?{|tr| tr.text.start_with?('◆ゲームマスター') && tr.text.include?('背徳者は初日')}

    result_role
  end

  #
  # 村の名前を返す
  #
  def village_name
    page.search('//font')
      .select{|font| font.text.include?("【モバマス】") }
      .first
      .text
      .slice(2..(-3))
  end

  #
  # モバマス村wiki更新用の文字列を生成する
  #
  def generate_wiki_text
    add_village_type = ''
    add_village_type = '&color(Maroon){(死神手帳)};' if village_type == '死神手帳'
    add_village_type = '&color(Maroon){(デビルトリガー)};' if village_type == 'デビルトリガー'
    add_village_type = '&color(Blue){(探偵)};' if village_type == '探偵'
    village_text = "[[#{village_name}#{add_village_type}}>#{wakamete_kako_url(@log_number)}]]"

    pop_text = "#{population}人"

    tr_array = first_night_tr
    powerup_fox_text = ''
    if tr_array.any?{|tr| tr.text.start_with?('◆ゲームマスター') && tr.text.include?('役職名と番号を振って念話で提出して下さい')}
      powerup_fox_text = '(霊力)'
    end

    role_hash = role
    role_text = ''
    role_text += "占#{role_hash['占い師'] == 1 ? '' : role_hash['占い師']}/" if role_hash.keys.include?('占い師')
    role_text += "霊#{role_hash['霊能者'] == 1 ? '' : role_hash['霊能者']}/" if role_hash.keys.include?('霊能者')
    role_text += "狩#{role_hash['狩人'] == 1 ? '' : role_hash['狩人']}/" if role_hash.keys.include?('狩人')
    role_text += "&color(pink,){猫#{role_hash['猫又'] == 1 ? '' : role_hash['猫又']}};/" if role_hash.keys.include?('猫又')
    role_text += "共#{role_hash['共有者'] == 1 ? '' : role_hash['共有者']}/" if role_hash.keys.include?('共有者')
    role_text += "村#{role_hash['村人'] == 1 ? '' : role_hash['村人']}/" if role_hash.keys.include?('村人')
    role_text += "狂#{role_hash['狂人'] == 1 ? '' : role_hash['狂人']}/" if role_hash.keys.include?('狂人') && role_hash['狂人'] != 0
    role_text += "&color(blueviolet,){狂信#{role_hash['狂信者'] == 1 ? '' : role_hash['狂信者']}};/"  if role_hash.keys.include?('狂信者')
    role_text += "&color(#FF0000,){狼#{role_hash['狼'] == 1 ? '' : role_hash['狼']}};/" if role_hash.keys.include?('狼')
    role_text += "&color(#FFA500,){狐#{role_hash['妖狐'] == 1 ? '' : role_hash['妖狐']}};#{powerup_fox_text}/" if role_hash.keys.include?('妖狐')
    role_text += "&color(orange,){背徳#{role_hash['背徳者'] == 1 ? '' : role_hash['背徳者']}};/"  if role_hash.keys.include?('背徳者')
    role_text = role_text[0, role_text.length - 1]

    end_date_text = "#{end_date}日"

    winner_text = '村人'
    winner_text = '&color(#FF0000,){人狼};' if winner_camp == '人狼'
    winner_text = '&color(#FFA500,){妖狐};' if winner_camp == '妖狐'
    winner_text = '&color(#32CD32,){引分};' if winner_camp == '引分'

    first_role_text = '村人'
    if first_death_role == '狂人'
      first_role_text = '&color(#FF0000,){狂人};'
    elsif first_death_role == '狂信者'
      first_role_text = '&color(blueviolet,){狂信};'
    elsif first_death_role == '背徳者'
      first_role_text = '&color(orange,){背徳};'
    elsif first_death_role != '村人'
      first_role_text = "&color(#008000,){#{first_death_role[0,2]}};"
    end

    sudden_death_text = sudden_death == 0 ? 'なし' : sudden_death

    "|#{@log_number}|#{village_text}|#{pop_text}|#{role_text}|#{end_date_text}|#{winner_text}|#{first_role_text}|#{sudden_death_text}|"
  end
end