require 'optparse'
require 'yaml'

def options
  option = {}
  OptionParser.new do |opt|
    opt.on('--last-log VALUE', '最後に追加されたログの番地(必須)') {|v| option[:last_log] = v }
    opt.parse!(ARGV)
  end

  option
end

if __FILE__ == $PROGRAM_NAME
  option = options
  if option[:last_log].nil?
    print("最後に追加されたログの番地を実行時に与えてください。\n")
    exit
  end

  create_yml_hash = {
      last_log: option[:last_log].to_i
  }

  open("./data.yml", "w") do |f|
    YAML.dump(create_yml_hash, f)
  end
end