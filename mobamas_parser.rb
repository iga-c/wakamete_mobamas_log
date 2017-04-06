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
end