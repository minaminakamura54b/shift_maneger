# 冪等性確保のため既存データを削除して再作成
puts "シードデータを作成中..."

Assignment.delete_all
Employee.delete_all
Site.delete_all
User.delete_all

# ── ユーザー ──
# シードのメールアドレスは実在しないため、確認メールを送らずに確認済み扱いで作成する
# 管理者
User.create!(
  email:                 "admin@example.com",
  password:              "password",
  password_confirmation: "password",
  admin:                 true,
  name:                  "管理者",
  confirmed_at:          Time.current
)

# 一般ユーザー（社員名 "田中 大輔" に紐づく）
User.create!(
  email:                 "tanaka.daisuke@example.com",
  password:              "password",
  password_confirmation: "password",
  name:                  "田中 大輔",
  confirmed_at:          Time.current
)

puts "ユーザー作成: 管理者 + 一般ユーザー 計2件"

# ── 現場 ──
sites = [
  { name: "渋谷再開発A工区",   address: "東京都渋谷区道玄坂1-1",     start_date: "2026-04-01", end_date: "2026-09-30" },
  { name: "新宿タワービル新築", address: "東京都新宿区西新宿2-3",     start_date: "2026-03-01", end_date: "2026-12-31" },
  { name: "横浜みなとみらい工事", address: "神奈川県横浜市西区みなとみらい4-5", start_date: "2026-05-01", end_date: "2026-10-31" },
  { name: "品川駅前整備",       address: "東京都港区港南2-1",         start_date: "2026-06-01", end_date: "2026-08-31" },
  { name: "川崎工場改修",       address: "神奈川県川崎市川崎区1-10",  start_date: "2026-04-15", end_date: "2026-07-31" },
  { name: "千葉ニュータウン造成", address: "千葉県印西市大塚1-1",    start_date: "2026-05-15", end_date: "2026-11-30" }
].map { |attrs| Site.create!(attrs) }
puts "現場作成: #{sites.count}件"

# ── 社員（30名）──
employees_data = [
  # 氏名
  [ "田中 大輔",  "tanaka.daisuke@example.com",  "090-1111-0001" ],
  [ "鈴木 健太",  "suzuki.kenta@example.com",    "090-1111-0002" ],
  [ "佐藤 翔",    "sato.sho@example.com",         "090-1111-0003" ],
  [ "高橋 涼介",  "takahashi.ryosuke@example.com", "090-1111-0004" ],
  [ "伊藤 拓也",  "ito.takuya@example.com",       "090-1111-0005" ],
  [ "渡辺 光",    "watanabe.hikaru@example.com",  "090-1111-0006" ],
  [ "山本 誠",    "yamamoto.makoto@example.com",  "090-1111-0007" ],
  [ "中村 隆",    "nakamura.takashi@example.com", "090-1111-0008" ],
  [ "小林 達也",  "kobayashi.tatsuya@example.com", "090-1111-0009" ],
  [ "加藤 浩二",  "kato.koji@example.com",        "090-1111-0010" ],
  [ "吉田 裕",    "yoshida.yutaka@example.com",   "090-1111-0011" ],
  [ "山田 康介",  "yamada.kosuke@example.com",    "090-1111-0012" ],
  [ "松本 直人",  "matsumoto.naoto@example.com",  "090-1111-0013" ],
  [ "井上 博",    "inoue.hiroshi@example.com",    "090-1111-0014" ],
  [ "木村 俊",    "kimura.shun@example.com",      "090-1111-0015" ],
  [ "林 和彦",    "hayashi.kazuhiko@example.com", "090-1111-0016" ],
  [ "清水 剛",    "shimizu.go@example.com",       "090-1111-0017" ],
  [ "山口 智",    "yamaguchi.satoshi@example.com", "090-1111-0018" ],
  [ "斎藤 義則",  "saito.yoshinori@example.com",  "090-1111-0019" ],
  [ "松田 篤",    "matsuda.atsushi@example.com",  "090-1111-0020" ],
  [ "福田 純",    "fukuda.jun@example.com",       "090-1111-0021" ],
  [ "岡田 雄太",  "okada.yuta@example.com",       "090-1111-0022" ],
  [ "長谷川 圭",  "hasegawa.kei@example.com",     "090-1111-0023" ],
  [ "石川 猛",    "ishikawa.takeshi@example.com", "090-1111-0024" ],
  [ "前田 聡",    "maeda.satoshi@example.com",    "090-1111-0025" ],
  [ "小川 信也",  "ogawa.nobuya@example.com",     "090-1111-0026" ],
  [ "藤原 真",    "fujiwara.makoto@example.com",  "090-1111-0027" ],
  [ "三浦 亮",    "miura.ryo@example.com",        "090-1111-0028" ],
  [ "後藤 徹",    "goto.toru@example.com",        "090-1111-0029" ],
  [ "西村 修",    "nishimura.osamu@example.com",  "090-1111-0030" ]
]

employees = employees_data.map do |name, email, phone|
  # User の after_create コールバックが先に作る場合があるため find_or_create_by! を使用
  Employee.find_or_create_by!(email: email) do |e|
    e.name  = name
    e.phone = phone
  end
end
puts "社員作成: #{employees.count}名"

# ── 配置（今月・来月を中心に作成）──
today = Date.today
assignments_created = 0

employees.each_with_index do |emp, i|
  # 各社員に1〜2件の配置をランダムに作成
  num_assignments = rand(1..2)
  num_assignments.times do
    site       = sites.sample
    start_day  = today - 5 + rand(30)         # 5日前〜25日後
    duration   = rand(3..14)                   # 3〜14日間
    end_day    = start_day + duration

    # 現場の期間内に収める
    start_day = [ start_day, site.start_date ].max
    end_day   = [ end_day,   site.end_date ].min
    next if start_day > end_day

    # 約半数に勤務時刻を設定
    if i.even?
      start_h = [ 7, 8, 8, 9 ].sample
      end_h   = start_h + [ 7, 8, 9 ].sample
      Assignment.create!(
        employee:   emp,
        site:       site,
        start_date: start_day,
        end_date:   end_day,
        start_time: format("%02d:00:00", start_h),
        end_time:   format("%02d:00:00", end_h)
      )
    else
      Assignment.create!(
        employee:   emp,
        site:       site,
        start_date: start_day,
        end_date:   end_day
      )
    end
    assignments_created += 1
  end
end

puts "配置作成: #{assignments_created}件"
puts "完了！ ログイン: admin@example.com / password"
