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
end