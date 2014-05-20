# -*- coding: utf-8 -*-
# RGB_DB: 色名のデータベースを扱うクラス
# 例:
# 	db = RGB_DB.new
# 	db.from_name_to_code("red")		# => "#FF0000"
# 	db['red']				# => "#FF0000" (same as above)
# 	db.from_code_to_name("#FF0000")	# => "red"
# 	db.from_code_to_names("#ff0000")	# => ["red", "red1", "Red(Web)"]
# 	db.find_similar_named_color("#ff0000")  # => ["red", "red1", "Red(Web)", "red2"]
class RGB_DB
  attr_reader :code2name, :name2code

  # RGB_DB.new: あたらしいインスタンスを作る
  def initialize
    @file = File.new("rgb.txt", "rb")

    @code2name = Hash.new { Array.new }
    @name2code = Hash.new

    @file.each_line do |line|
      line.chomp!
      if line =~ /^\s*(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\t\t(.*)$/
        r = $1; g = $2; b = $3; name = $4
        code = sprintf("#%02X%02X%02X", r.to_i, g.to_i, b.to_i)
        if @code2name[code].empty?
          @code2name[code] = []
        end
        @code2name[code] << name
        @name2code[name.downcase] = code
      end
    end
  end

  # RGB_DB#from_code_to_name(str)
  # 	"#FF0000" のような数値表記の色 str を "red" のような名前に変換する
  def from_code_to_name(str)
    @code2name[str.upcase][0]
  end

  # RGB_DB#from_code_to_names(str)
  # 	数値表記に対応する色名を ["name1", "name2", ... ] の形で全て返す
  def from_code_to_names(str)
    @code2name[str.upcase]
  end

  # RGB_DB#from_name_to_code(str)
  # 	色名から数値表記を得る
  def from_name_to_code(str)
    @name2code[str.downcase]
  end
  alias :[] :from_name_to_code

  # 値の近い名前のある色名を ["name1", "name2", ... ] の形で返す
  def find_similar_named_color(str)
    if str[0] != "#"
      str = self[str]
      if str.empty?
        raise "no such color"
      end
    end
    # RGB of the target color
    str =~ /^#(..)(..)(..)$/
    tr, tg, tb = $1.hex, $2.hex, $3.hex
    rv = []
    @code2name.each_pair do |key, value|
      key =~ /^#(..)(..)(..)$/
      r, g, b = $1.hex, $2.hex, $3.hex
      if (tr - r).abs < 15 and 
          (tg - g).abs < 15 and
          (tb - b).abs < 15 and
          [r, g, b] != [tr, tg, tb] then
        rv +=  value
      end
    end
    return rv
  end
end
