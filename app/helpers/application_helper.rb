module ApplicationHelper
  # 現場のID（またはID未確定時は現場名）から色相を算出する
  # カレンダーの配置ブロックと凡例で同じ色になるよう、算出式を1箇所に集約する
  def site_color_hue(key)
    base = key.is_a?(String) ? key.sum : key
    base * 61 % 360
  end
end
