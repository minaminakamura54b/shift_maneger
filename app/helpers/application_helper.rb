module ApplicationHelper
  # 識別子（IDまたは名前文字列）から色相を算出する
  # カレンダーの配置ブロックと凡例で常に同じ色になるよう、算出式を1箇所に集約する
  # （全体表記では現場ごと、現場ごと表記では社員ごとに色分けするため、どちらのキーでも使えるようにしている）
  def color_hue_for(key)
    base = key.is_a?(String) ? key.sum : key
    base * 61 % 360
  end

  # 秒数を「◯時間◯分」の表記に変換する（勤怠の実働時間表示で使用）
  def format_duration(seconds)
    total_minutes = (seconds / 60).floor
    "#{total_minutes / 60}時間#{total_minutes % 60}分"
  end
end
