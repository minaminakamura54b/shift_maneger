module ApplicationHelper
  # 識別子（IDまたは名前文字列）から色相を算出する
  # カレンダーの配置ブロックと凡例で常に同じ色になるよう、算出式を1箇所に集約する
  # （全体表記では現場ごと、現場ごと表記では社員ごとに色分けするため、どちらのキーでも使えるようにしている）
  def color_hue_for(key)
    base = key.is_a?(String) ? key.sum : key
    base * 61 % 360
  end
end
