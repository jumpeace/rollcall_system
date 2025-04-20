require 'sinatra/namespace'
require 'sinatra'

require './controllers/user.rb'
require './helpers/error.rb'
require './helpers/base.rb'
require './controllers/student.rb'
require './controllers/staff.rb'
require './controllers/onduty.rb'
require './validations/user.rb'
require './validations/student.rb'
require './validations/staff.rb'
require './models/user.rb'
require './models/student.rb'
require './models/staff.rb'
require './models/room.rb'
require './models/floor.rb'
require './models/building.rb'
require './models/department.rb'
require './models/onduty.rb'

require './helpers/user_token.rb'
require './helpers/time.rb'
require './helpers/task.rb'
require './env.rb'

set :environment, :production
# セッションの設定
set :sessions,
  expire_after: 7200,
  secret: $session_secret # env.rbで設定が必要

# スタッフとしてログインしているか判定する
def staff_login?
  valid_user_token?(session[:user_token], session[:user_id]) && StaffController.staff?(session[:user_id])
end

# 管理者のスタッフとしてログインしているか判定する
def admin_staff_login?
  valid_user_token?(session[:user_token], session[:user_id]) && StaffController.admin_staff?(session[:user_id])
end

# 普通のスタッフとしてログインしているか判定する
def normal_staff_login?
  valid_user_token?(session[:user_token], session[:user_id]) && StaffController.normal_staff?(session[:user_id])
end

# 指定された年月日の当直としてログインしているか判定する
def onduty_login?(time)
  valid_user_token?(session[:user_token], session[:user_id]) && OndutyController.onduty?(session[:user_id], time)
end

# 学生としてログインしているか判定する
def student_login?
  valid_user_token?(session[:user_token], session[:user_id]) && StudentController.student?(session[:user_id])
end

# ログインしているか判定する
def anyone_login?
  student_login? || staff_login?
end

# 学生かスタッフかによってデフォルトのリダイレクトurlを返す
def get_default_url
  return '/staff/mypage/' if staff_login?

  return '/student/mypage/' if student_login?
  nil
end

# ランダムな乱数にする
srand(Time.now.to_i)

# 定期タスクを実行する
Thread.start do
  exec_tasks()
end

# CORSエラーが出ないようにする
before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

# Ajaxで利用するAPI
namespace '/api' do
  # 号館の番号による号館の取得
  get '/building/' do
    body FloorModel.gets_by_building(params[:building], is_format: true).to_json
  end

  # 号館の番号と階の番号による階の取得
  get '/floor/' do
    body RoomModel.gets_by_building_floor(params[:building], params[:floor], is_format: true).to_json
  end

  # 号館の番号と階の番号と部屋番号の下2桁による部屋の取得
  get '/room/' do
    body RoomModel.gets_by_building_floor_digit_ten(params[:building], params[:floor], params[:digit_ten].to_i, is_format: true).to_json
  end

  # 年月による当直の取得
  get '/onduty/' do
    body OndutyModel.gets_by_year_month(params[:year].to_i, params[:month].to_i, is_format: true).to_json
  end

  # 号館, 階と年月日による点呼表の取得
  get '/rollcall/' do
    result = { students: [], student_count: 0 }
    students = StudentModel.gets_by_building_floor(params[:building], params[:floor], is_format: true)[:students]
    students.each do |student|
      rollcall = RollcallModel.get_by_student_time(student[:id], {
        year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i
      }, is_format: true)
      student = student.merge({ rollcall: {
        is_student_done: rollcall[:is_student_done], is_onduty_done: rollcall[:is_onduty_done], student_img_name: rollcall[:student_img_name] }
      }) unless rollcall == {}
      result[:students].push(student)
    end

    result[:student_count] = result[:students].length
    body result.to_json
  end

  # バリデーション結果を返すAPI
  namespace '/valid' do
    # ユーザーのバリデーション
    namespace '/user' do
      # メールアドレス
      get '/email/' do
        body UserValid::Fields.email(params[:email]).to_json
      end
      # 名前
      get '/name/' do
        body UserValid::Fields.name(params[:name]).to_json
      end
      # パスワード
      get '/passwd/' do
        body UserValid::Fields.passwd(params[:raw_passwd], params[:config_passwd]).to_json
      end
    end

    # 学生
    namespace '/student' do
      # 学籍番号
      get '/id/' do
        result = { is_ok: false }
        field_result = {}

        # 学籍番号でバリデーション
        field_result[:id] = StudentValid::Fields.id(params[:id])
        if field_result[:id][:is_ok]
          # メールアドレスでバリデーション
          field_result[:email] = UserValid::Fields.email("#{params[:id]}@g.nagano-nct.ac.jp")
          if field_result[:email][:is_ok]
            result[:is_ok] = true
          else
            result[:err] = field_result[:email][:err]
          end
        else
          result[:err] = field_result[:id][:err]
        end

        body result.to_json
      end

      # 学年
      get '/grade/' do
        body StudentValid::Fields.grade(params[:grade]).to_json
      end

      # 学科
      get '/department_id/' do
        body StudentValid::Fields.department_id(params[:department_id]).to_json
      end

      # 部屋番号
      get '/room_num/' do
        body StudentValid::Fields.room_num(params[:room_num], id: params[:id]).to_json
      end
    end
  end
end

namespace '/user' do
  # ログアウト処理
  namespace '/logout' do
    post '/process/' do
      redirect '/student/login/form/' unless anyone_login?

      # セッションを削除することでログアウトする
      session.clear
      redirect '/student/login/form/'
    end
  end
end

namespace '/student' do
  # 学生のログイン処理
  namespace '/login' do
    get '/form/' do
      default_url = get_default_url
      # すでにログインしている場合
      redirect default_url unless default_url.nil?

      # Webページ内のリンク
      @links = [{ path: '/staff/login/form/', name: 'ログインフォーム(スタッフ)' }]

      # 学生のログイン処理でのエラーメッセージ
      @err = session[:err_msg]
      # 以前入力したフォームのデータ
      @form_data = session[:form_data]
      session[:err_msg] = nil
      session[:form_data] = nil

      erb :'pages/student/login_form'
    end

    # 学生のログイン処理
    post '/process/' do
      # バリデーションの結果を格納する
      login_result = StudentController.login({ id: params[:student_id], passwd: params[:passwd] })

      # バリデーションが失敗した場合はログインしない
      unless login_result[:is_ok]
        session[:err_msg] = login_result[:err][:msg]
        session[:form_data] = params
        session[:form_data][:passwd] = nil
        redirect '/student/login/form/'
      end

      # ログイン処理
      # ユーザーIDとユーザートークンをセッションに格納する
      session[:user_id] = login_result[:data][:user_id]
      session[:user_token] = get_user_token(login_result[:data][:user_id])

      # 学生のマイページにリダイレクトする
      redirect '/student/mypage/'
    end
  end

  # 学生のマイページ
  get '/mypage/' do
    # 学生としてログインしていない場合は学生のログインフォームにリダイレクトさせる
    redirect '/student/login/form/' unless student_login?

    # ログインしている学生
    @logined_student = StudentModel.get_by_user_id(session[:user_id], is_format: true)
    # お知らせ
    @notifies = []
    # Webページ内のリンク
    @links = [{ path: '/rollcall/form/', name: '点呼フォーム' }]

    # アクセス当日の点呼
    rollcall_time = RollcallController.rollcalling_time
    unless MyTime.compare_time(rollcall_time[:start][:hour], rollcall_time[:start][:minute]) == 'future'
      unless RollcallController.rollcall_today_onduty_done?(@logined_student[:id])
        now = Time.now
        @notifies.push("#{now.year}年#{now.month}月#{now.day}日の点呼をしてください。")
      end
    end

    erb :'pages/student/mypage'
  end
end

namespace '/staff' do
  # スタッフのログインフォーム
  namespace '/login' do
    get '/form/' do
      default_url = get_default_url
      # すでにログインしている場合
      redirect default_url unless default_url.nil?

      # Webページ内のリンク
      @links = [{ path: '/student/login/form/', name: 'ログインフォーム(学生)' }]

      # スタッフのログイン処理でのエラーメッセージ
      @err = session[:err_msg]
      # 以前入力したフォームのデータ
      @form_data = session[:form_data]
      session[:err_msg] = nil
      session[:form_data] = nil

      erb :'pages/staff/login_form'
    end

    # スタッフのログイン処理
    post '/process/' do
      # バリデーションの結果を格納する
      login_result = StaffController.login({ email: params[:email], passwd: params[:passwd] })

      # バリデーションが失敗した場合はログインしない
      unless login_result[:is_ok]
        session[:err_msg] = login_result[:err][:msg]
        session[:form_data] = params
        session[:form_data][:passwd] = nil
        redirect '/staff/login/form/'
      end

      # ログイン処理
      # ユーザーIDとユーザートークンをセッションに格納する
      session[:user_id] = login_result[:data][:user_id]
      session[:user_token] = get_user_token(login_result[:data][:user_id])
      
      # 学生のマイページにリダイレクトする
      redirect '/staff/mypage/'
    end
  end

  # スタッフのマイページ
  get '/mypage/' do
    # スタッフとしてログインしていない場合はスタッフのログインフォームにリダイレクトさせる
    redirect '/staff/login/form/' unless staff_login?

    # ログインしているスタッフ
    @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
    # お知らせ
    @notifies = []
    # Webページ内のリンク
    @links = [{ path: '/rollcall/list/', name: '点呼管理ページ' }]

    # 管理者の場合は管理者ページへのリンクを追加する
    @links.push({ path: '/admin/', name: '管理者ページ' }) if admin_staff_login?

    # アクセスした当日が当直の場合は表示する
    now = Time.now
    @notifies.push('今日は当直です。') if OndutyController.onduty?(session[:user_id], {
      year: now.year, month: now.month, date: now.day
    })

    # 今後の当直を表示する
    @onduties = OndutyModel.gets_by_staff_now_future(@logined_staff[:id], is_format: true)[:onduties]

    erb :'pages/staff/mypage'
  end
end

namespace '/rollcall' do
  # 点呼を行うフォーム
  get '/form/' do
    # 学生しかアクセスできない
    redirect '/student/login/form/' unless student_login?

    # アクセス
    session[:referrer] = request.path
    # 点呼時間内でない場合
    redirect '/rollcall/unable/' unless RollcallController.able_rollcall?

    # ログインしている学生
    @logined_student = StudentModel.get_by_user_id(session[:user_id], is_format: true)

    # 点呼済の場合
    redirect '/rollcall/done/' if RollcallController.rollcall_today_student_done?(@logined_student[:id])

    # Webページ内のリンク
    @links = []

    # 学籍番号
    @student_id = @logined_student[:id]

    # 点呼でのエラーメッセージ
    @err = session[:err_msg]
    session[:err_msg] = nil

    # 点呼時間を取得
    rollcall_time = RollcallController.rollcalling_time
    @start_time = MyTime.str(rollcall_time[:start])
    @due_time = MyTime.str(rollcall_time[:due])

    erb :'pages/rollcall/form'
  end

  # 学生の点呼処理
  post '/process/' do
    # 学生としてログインしていない場合は学生のログインフォームにリダイレクトさせる
    redirect '/student/login/form/' unless student_login?

    # ユーザーIDから学生を取得
    student = StudentModel.get_by_user_id(session[:user_id], is_format: true)
    # 学生の点呼処理を点呼のControllerを利用して行う
    rollcall_result = RollcallController.rollcall_today_by_student(student[:id], { student_img: params[:student_img] })

    # 学生の点呼処理が失敗した場合はエラーメッセージを格納し, 
    # もう一度点呼フォームにリダイレクトする
    unless rollcall_result[:is_ok]
      session[:err_msg] = rollcall_result[:err][:msg]
      redirect '/rollcall/form/'
    end

    # 学生の点呼処理が成功した場合は点呼待機画面を表示させる
    redirect '/rollcall/done/'
  end

  # 点呼時間内でなく点呼ができない時にリダイレクトされるページ
  get '/unable/' do
    # 学生としてログインしていない場合
    redirect '/student/login/form/' unless student_login?

    # 点呼フォームからリダイレクトされていない場合
    is_valid = !session[:referrer].nil? && session[:referrer] == '/rollcall/form/'
    session[:referrer] = nil
    redirect '/rollcall/form/' unless is_valid

    # ログインしている学生
    @logined_student = StudentModel.get_by_user_id(session[:user_id], is_format: true)
    # Webページ内のリンク
    @links = []

    # 点呼時間の開始時間と終了時間を取得
    rollcall_time = RollcallController.rollcalling_time
    @start_time = MyTime.str(rollcall_time[:start])
    @due_time = MyTime.str(rollcall_time[:due])

    erb :'pages/rollcall/unable'
  end

  # 点呼が行われた時にリダイレクトされるページ
  get '/done/' do
    # 学生としてログインしていない場合は学生のログインフォームにリダイレクトさせる
    redirect '/student/login/form/' unless student_login?

    # 点呼フォームからリダイレクトされていない場合
    is_valid = !session[:referrer].nil? && session[:referrer] == '/rollcall/form/'
    session[:referrer] = nil
    redirect '/rollcall/form/' unless is_valid

    # ログインしている学生
    @logined_student = StudentModel.get_by_user_id(session[:user_id], is_format: true)

    # Webページ内のリンク
    @links = []

    # 点呼確認が完了しているかを示すメッセージ
    @mes = nil
    @mes = '点呼確認待ちです' if RollcallController.rollcall_today_student_done?(@logined_student[:id])
    @mes = '点呼が完了しました' if RollcallController.rollcall_today_onduty_done?(@logined_student[:id])

    # 学生の点呼がそもそも終わっていない場合
    redirect '/rollcall/form/' if @mes.nil?

    erb :'pages/rollcall/done'
  end

  # 以下スタッフしかアクセス不可能
  get '/list/' do
    # スタッフとしてログインしていない場合はスタッフのログインフォームにリダイレクトさせる
    redirect '/staff/login/form/' unless staff_login?

    # ログインしているスタッフ
    @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
    # Webページ内のリンク
    @links = [
      { path: '/admin/', name: '管理者ページ' },
      { path: '/admin/student/', name: '学生管理ページ' },
      { path: '/admin/staff/', name: 'スタッフ管理ページ' },
      { path: '/admin/onduty/', name: '当直管理ページ' },
    ]

    # クエリパラメータに年月日の情報がある場合はその年月日で検索
    # ない場合は現在の日にちで検索
    now = Time.now
    @year = params[:year].nil? ? now.year.to_s :  params[:year]
    @month = params[:month].nil? ? now.month.to_s : params[:month]
    @date = params[:date].nil? ? now.day.to_s : params[:date]

    # 階テーブルで1番目の階を選ぶ
    floors = FloorModel.gets_all(is_format: true)[:floors]
    selected_floor = floors.length.positive? ? floors[0] : nil
    @building_num = params[:building].nil? ?
      (selected_floor.nil? ? '' : selected_floor[:building_num]) : params[:building]
    @floor_num = params[:floor].nil? ?
      (selected_floor.nil? ? '' : selected_floor[:floor_num]) : params[:floor]

    # 点呼確認, 点呼強制確認, 点呼やり直し処理でのエラーメッセージ
    @errs = session[:err_msgs].nil? ? [] : session[:err_msgs]
    session[:err_msgs] = nil

    erb :'pages/rollcall/list'
  end

  # 点呼確認を行う
  # クエリパラメータで年月日, 学籍番号(複数可)を指定する必要がある
  post '/check/' do
    # スタッフとしてログインしていない場合はスタッフのログインフォームにリダイレクトさせる
    redirect '/staff/login/form/' unless staff_login?

    # 点呼確認の処理を点呼のControllerを利用して行う
    check_result = RollcallController.checks_by_onduty(params[:student_ids].split(','), {
      year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i,
    })

    # 処理が失敗した場合はエラーメッセージを格納し, 
    # 点呼管理ページにリダイレクトする
    unless check_result[:is_ok]
      session[:err_msgs] = []
      check_result[:errs].each do |err|
        session[:err_msgs].push(err[:msg])
      end
      redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
    end

    # 点呼管理ページにリダイレクトする
    redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
  end

  # 点呼の強制確認を行う
  # クエリパラメータで年月日, 学籍番号(複数可)を指定する必要がある
  post '/forcedcheck/' do
    # スタッフとしてログインしていない場合はスタッフのログインフォームにリダイレクトさせる
    redirect '/staff/login/form/' unless staff_login?

    # 点呼強制確認の処理を点呼のControllerを利用して行う
    forcedcheck_result = RollcallController.forcedchecks_by_onduty(params[:student_ids].split(','), {
      year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i,
    })

    # 処理が失敗した場合はエラーメッセージを格納し, 
    # 点呼管理ページにリダイレクトする
    unless forcedcheck_result[:is_ok]
      session[:err_msgs] = []
      forcedcheck_result[:errs].each do |err|
        session[:err_msgs].push(err[:msg])
      end
      redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
    end

    # 点呼管理ページにリダイレクトする
    redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
  end

  # 点呼のやり直しを行う
  # クエリパラメータで年月日, 学籍番号(複数可)を指定する必要がある
  post '/startover/' do
    # スタッフとしてログインしていない場合はスタッフのログインフォームにリダイレクトさせる
    redirect '/staff/login/form/' unless staff_login?

    # 点呼のやり直しの処理を点呼のControllerを利用して行う
    startover_result = RollcallController.startovers_by_onduty(params[:student_ids].split(','), {
      year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i,
    })

    # 処理が失敗した場合はエラーメッセージを格納し, 
    # 点呼管理ページにリダイレクトする
    unless startover_result[:is_ok]
      session[:err_msgs] = []
      startover_result[:errs].each do |err|
        session[:err_msgs].push(err[:msg])
      end
      redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
    end

    # 処理が成功した場合は点呼管理ページにリダイレクトする
    redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
  end
end

namespace '/admin' do
  before do
    # '/admin/...' のURLは管理者のスタッフしかアクセス不可能
    redirect '/staff/login/form/' unless admin_staff_login?
  end

  get '/' do
    # ログインしているスタッフ
    @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
    # Webページ内のリンク
    @links = [
      { path: '/admin/student/', name: '学生管理ページ' },
      { path: '/admin/staff/', name: 'スタッフ管理ページ' },
      { path: '/admin/onduty/', name: '当直管理ページ' },
      { path: '/rollcall/list/', name: '点呼管理ページ' }
    ]

    erb :'pages/admin/root'
  end

  namespace '/student' do
    # 学生一覧表示ページ
    get '/' do
      # ログインしているスタッフ
      @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
      # Webページ内のリンク
      @links = [
        { path: '/admin/', name: '管理者ページ' },
        { path: '/admin/staff/', name: 'スタッフ管理ページ' },
        { path: '/admin/onduty/', name: '当直管理ページ' },
        { path: '/rollcall/list/', name: '点呼管理ページ' }
      ]

      # 学生の一覧を取得
      @students = StudentModel.gets_all(is_format: true)[:students]

      # 学生の編集, パスワード編集, 削除で成功した場合のメッセージ
      @msg = session[:msg]
      session[:msg] = nil

      # 学生の削除で失敗した場合のエラーメッセージ
      @err = session[:err_msg]
      session[:err_msg] = nil

      erb :'pages/admin/student/root'
    end

    # 学生の削除
    post '/delete/process/' do
      # 学生の削除処理を学生のControllerを利用して行う
      delete_result = StudentController.deletes(params[:student_ids].split(','))

      # 処理が失敗した場合はエラーメッセージを格納し, 
      # 学生管理ページにリダイレクトする
      unless delete_result[:is_ok]
        session[:err_msg] = delete_result[:err][:msg]
        redirect '/admin/student/'
      end

      # 処理が成功した場合は成功メッセージを格納し, 
      # 学生管理ページにリダイレクトする
      session[:msg] = '学生の削除に成功しました'
      redirect '/admin/student/'
    end

    namespace '/create' do
      # 学生の作成フォーム
      get '/form/' do
        # ログインしているスタッフ
        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        # Webページ内でのリンク
        @links = [
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/admin/onduty/', name: '当直管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        # 号館の一覧
        @departments = DepartmentModel.gets_all(is_format: true)[:departments]

        # 学生作成でのエラーメッセージ
        @err = session[:err_msg]
        session[:err_msg] = nil
        # 学生作成での成功メッセージ
        @msg = session[:msg]
        session[:msg] = nil
        # 以前入力したフォームデータ
        @form_data = session[:form_data]
        session[:form_data] = nil

        erb :'pages/admin/student/create_form'
      end

      # 学生作成処理
      post '/process/' do
        # 学生の作成処理を学生のControllerを利用して行う
        create_result = StudentController.create({
            student_id: params[:student_id],
            user_name: params[:user_name],
            grade: params[:grade],
            department_id: params[:department_id],
            room_num: params[:room_num],
            img: params[:student_img],
            raw_passwd:  params[:raw_passwd],
            config_passwd: params[:config_passwd]
          })

        # 処理が失敗した場合エラーメッセージと入力データを格納し, 
        # 学生作成フォームにリダイレクトする
        unless create_result[:is_ok]
          session[:err_msg] = create_result[:err][:msg]
          session[:form_data] = params
          session[:form_data][:student_img] = nil
          session[:form_data][:raw_passwd] = nil
          session[:form_data][:config_passwd] = nil
          redirect '/admin/student/create/form/'
        end

        # 処理が成功した場合は成功メッセージを格納し, 
        # 学生作成ページにリダイレクトする
        session[:msg] = '学生の作成に成功しました。'
        redirect '/admin/student/create/form/'
      end
    end

    namespace '/update' do
      # 学生編集フォーム
      get '/:student_id/form/' do
        # 編集したい学生の情報を取得
        get_result_by_format = StudentModel.get_by_id(params[:student_id], is_format: true)
        # 編集したい学生がいない場合
        redirect '/admin/student/' if get_result_by_format.nil?

        # ログインしているスタッフ
        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        # Webページ内でのリンク
        @links = [
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/admin/onduty/', name: '当直管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        # 編集したい学生の情報をレコードで取得
        get_result_by_record = StudentModel.get_by_id(params[:student_id])

        # 編集したい学生の元々の情報をフォームデータに格納
        form_data_by_get_result = {
          user_name: get_result_by_format[:user][:name],
          grade: get_result_by_format[:grade],
          department_id: get_result_by_record.department_id,
          room_num: get_result_by_format[:room][:room]
        }

        # 号館一覧を取得
        @departments = DepartmentModel.gets_all(is_format: true)[:departments]

        # 学籍番号
        @student_id = params[:student_id]
        # 学生の変更処理でのエラーメッセージ
        @err = session[:err_msg]
        session[:err_msg] = nil
        # 以前の入力情報が残っていたらその情報をフォームデータに格納
        # なかったら元々の情報をフォームデータに格納
        @form_data = session[:form_data].nil? ? form_data_by_get_result : session[:form_data]
        session[:form_data] = nil

        erb :'pages/admin/student/update_form'
      end

      # 学生の変更処理
      post '/:student_id/process/' do
        # 学生の変更処理を学生のControllerを利用して行う
        update_result = StudentController.update(params[:student_id].to_i, {
            user_name: params[:user_name],
            grade: params[:grade],
            department_id: params[:department_id],
            room_num: params[:room_num]
          })

        # 処理が失敗した場合エラーメッセージと入力データを格納し, 
        # 学生編集フォームにリダイレクトする
        # ただし学生が見つからなかった場合は学生管理ページにリダイレクトする
        unless update_result[:is_ok]
          session[:err_msg] = update_result[:err][:msg]

          redirect '/admin/student/' if update_result[:err][:type] == $err_types[:NOT_FOUND]

          session[:form_data] = params
          redirect "/admin/student/update/#{params[:student_id]}/form/"
        end

        # 処理が成功した場合は成功メッセージを格納し, 
        # 学生管理ページにリダイレクトする
        session[:msg] = '学生の更新に成功しました。'
        redirect '/admin/student/'
      end
    end

    namespace '/passwd' do
      namespace '/update' do
        # 学生パスワード編集フォーム
        get '/:student_id/form/' do
          # パスワードを編集したい学生の情報を取得
          get_result = StudentModel.get_by_id(params[:student_id])
          # パスワードを編集したい学生がいない場合
          redirect '/admin/student/' if get_result.nil?

          # ログインしているスタッフ
          @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
          # Webページ内でのリンク
          @links = [
            { path: '/admin/student/', name: '学生管理ページ' },
            { path: '/admin/', name: '管理者ページ' },
            { path: '/admin/staff/', name: 'スタッフ管理ページ' },
            { path: '/admin/onduty/', name: '当直管理ページ' },
            { path: '/rollcall/list/', name: '点呼管理ページ' }
          ]

          # 学籍番号
          @student_id = params[:student_id]
          # 学生のパスワード変更処理でのエラーメッセージ
          @err = session[:err_msg]
          session[:err_msg] = nil

          erb :'pages/admin/student/update_passwd_form'
        end

      # 学生のパスワード変更処理
        post '/:student_id/process/' do
          # 学生のパスワード変更処理を学生のControllerを利用して行う
          update_result = StudentController.update_passwd(params[:student_id],
            { now_passwd: params[:now_passwd], new_passwd: params[:new_passwd] })

          # 処理が失敗した場合エラーメッセージと入力データを格納し, 
          # 学生パスワード編集フォームにリダイレクトする
          # ただし学生が見つからなかった場合は学生管理ページにリダイレクトする
          unless update_result[:is_ok]
            redirect '/admin/student/' if update_result[:err][:type] == $err_types[:NOT_FOUND]

            session[:err_msg] = update_result[:err][:msg]
            redirect "/admin/student/passwd/update/#{params[:student_id]}/form/"
          end

          # 処理が成功した場合は成功メッセージを格納し, 
          # 学生管理ページにリダイレクトする
          session[:msg] = 'パスワード変更に成功しました。'
          redirect '/admin/student/'
        end
      end
    end
  end

  namespace '/staff' do
    # スタッフ一覧表示ページ
    get '/' do
      # ログインしているスタッフ
      @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
      # Webページ内のリンク
      @links = [
        { path: '/admin/', name: '管理者ページ' },
        { path: '/admin/student/', name: '学生管理ページ' },
        { path: '/admin/onduty/', name: '当直管理ページ' },
        { path: '/rollcall/list/', name: '点呼管理ページ' }
      ]

      # スタッフの一覧を取得
      @staffs = StaffModel.gets_all(is_format: true)[:staffs]

      # スタッフの編集, パスワード編集, 削除で成功した場合のメッセージ
      @msg = session[:msg]
      session[:msg] = nil

      # スタッフの削除で失敗した場合のエラーメッセージ
      @errs = []
      @errs = session[:err_msgs] unless session[:err_msgs].nil?
      session[:err_msgs] = nil
      @errs.push(session[:err_msg]) unless session[:err_msg].nil?
      session[:err_msg] = nil

      erb :'pages/admin/staff/root'
    end

    # スタッフの削除
    post '/delete/process/' do
      # スタッフの削除処理をスタッフのControllerを利用して行う
      delete_result = StaffController.deletes(params[:staff_ids].split(','))

      # 処理が失敗した場合はエラーメッセージを格納し, 
      # スタッフ管理ページにリダイレクトする
      unless delete_result[:is_ok]
        session[:err_msgs] = []
        delete_result[:errs].each do |err|
          session[:err_msgs].push(err[:msg])
        end
        redirect '/admin/staff/'
      end

      # 処理が成功した場合は成功メッセージを格納し, 
      # スタッフ管理ページにリダイレクトする
      session[:msg] = 'スタッフの削除に成功しました'
      redirect '/admin/staff/'
    end

    namespace '/normal/create' do
      # 普通のスタッフの作成フォーム
      get '/form/' do
        # ログインしているスタッフ
        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        # Webページ内でのリンク
        @links = [
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/onduty/', name: '当直管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        # スタッフ作成での成功メッセージ
        @msg = session[:msg]
        session[:msg] = nil
        # スタッフ作成でのエラーメッセージ
        @err = session[:err_msg]
        session[:err_msg] = nil
        # 以前入力したフォームデータ
        @form_data = session[:form_data]
        session[:form_data] = nil

        erb :'pages/admin/staff/normal_create_form'
      end

      # 普通スタッフ作成処理
      post '/process/' do
        # スタッフの作成処理をスタッフのControllerを利用して行う
        create_result = StaffController.create_normal({
            email: params[:email],
            user_name: params[:user_name],
            raw_passwd: params[:raw_passwd],
            config_passwd: params[:config_passwd]
          })
          
        # 処理が失敗した場合エラーメッセージと入力データを格納し, 
        # 普通スタッフ作成フォームにリダイレクトする
        unless create_result[:is_ok]
          session[:err_msg] = create_result[:err][:msg]
          session[:form_data] = params
          session[:form_data][:raw_passwd] = nil
          session[:form_data][:config_passwd] = nil
          redirect '/admin/staff/normal/create/form/'
        end

        # 処理が成功した場合は成功メッセージを格納し, 
        # 普通スタッフ作成ページにリダイレクトする
        session[:msg] = 'スタッフの作成に成功しました。'
        redirect '/admin/staff/normal/create/form/'
      end
    end

    namespace '/update' do
      # スタッフ編集フォーム
      get '/:staff_id/form/' do
        # 編集したいスタッフの情報を取得
        get_result = StaffModel.get_by_id(params[:staff_id], is_format: true)
        # 編集したいスタッフがいない場合
        redirect '/admin/staff/' if get_result.nil?

        # ログインしているスタッフ
        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        # Webページ内でのリンク
        @links = [
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/onduty/', name: '当直管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        # 編集したいスタッフの元々の情報をフォームデータに格納
        form_data_by_get_result = {
          email: get_result[:user][:email],
          user_name: get_result[:user][:name],
        }

        # スタッフID
        @staff_id = params[:staff_id]
        # スタッフの変更処理でのエラーメッセージ
        @err = session[:err_msg]
        session[:err_msg] = nil
        # 以前の入力情報が残っていたらその情報をフォームデータに格納
        # なかったら元々の情報をフォームデータに格納
        @form_data = session[:form_data].nil? ? form_data_by_get_result : session[:form_data]
        session[:form_data] = nil

        erb :'pages/admin/staff/update_form'
      end

      # スタッフの変更処理
      post '/:staff_id/process/' do
        # スタッフの変更処理をスタッフのControllerを利用して行う
        update_result = StaffController.update(params[:staff_id], {
            user_name: params[:user_name]
          })

        # 処理が失敗した場合エラーメッセージと入力データを格納し, 
        # スタッフ編集フォームにリダイレクトする
        # ただしスタッフが見つからなかった場合はスタッフ管理ページにリダイレクトする
        unless update_result[:is_ok]
          redirect '/admin/staff/' if update_result[:err][:type] == $err_types[:NOT_FOUND]

          session[:err_msg] = update_result[:err][:msg]
          session[:form_data] = params
          redirect "/admin/staff/update/#{params[:staff_id]}/form/"
        end

        # 処理が成功した場合は成功メッセージを格納し, 
        # スタッフ管理ページにリダイレクトする
        session[:update_staff_mes] = 'スタッフの更新に成功しました。'
        redirect '/admin/staff/'
      end
    end

    namespace '/passwd' do
      namespace '/update' do
        # スタッフパスワード編集フォーム
        get '/:staff_id/form/' do
          # パスワードを編集したいスタッフの情報を取得
          get_result = StaffModel.get_by_id(params[:staff_id], is_format: true)
          # パスワードを編集したいスタッフがいない場合
          redirect '/admin/student/' if get_result.nil?

          # ログインしているスタッフ
          @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
          # Webページ内でのリンク
          @links = [
            { path: '/admin/staff/', name: 'スタッフ管理ページ' },
            { path: '/admin/', name: '管理者ページ' },
            { path: '/admin/student/', name: '学生管理ページ' },
            { path: '/admin/onduty/', name: '当直管理ページ' },
            { path: '/rollcall/list/', name: '点呼管理ページ' }
          ]

          # 編集するスタッフの情報
          @staff = get_result
          # スタッフのパスワード変更処理でのエラーメッセージ
          @err = session[:err_msg]
          session[:err_msg] = nil

          erb :'pages/admin/staff/update_passwd_form'
        end

        # スタッフのパスワード変更処理
        post '/:staff_id/process/' do
          # スタッフのパスワード変更処理をスタッフのControllerを利用して行う
          update_result = StaffController.update_passwd(params[:staff_id],
          { now_passwd: params[:now_passwd], new_passwd: params[:new_passwd]} )

        # 処理が失敗した場合エラーメッセージと入力データを格納し, 
        # スタッフパスワード編集フォームにリダイレクトする
        # ただしスタッフが見つからなかった場合はスタッフ管理ページにリダイレクトする
          unless update_result[:is_ok]
            redirect '/admin/staff/' if update_result[:err][:type] == $err_types[:NOT_FOUND]

            session[:err_msg] = update_result[:err][:msg]
            redirect "/admin/staff/passwd/update/#{params[:staff_id]}/form/"
          end

          # 処理が成功した場合は成功メッセージを格納し, 
          # スタッフ管理ページにリダイレクトする
          session[:update_staff_passwd_mes] = 'パスワード変更に成功しました'
          redirect '/admin/staff/'
        end
      end
    end
  end

  namespace '/onduty' do
    # 当直一覧表示ページ
    get '/' do
      # ログインしているスタッフ
      @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
      # Webページ内のリンク
      @links = [
        { path: '/admin/', name: '管理者ページ' },
        { path: '/admin/student/', name: '学生管理ページ' },
        { path: '/admin/staff/', name: 'スタッフ管理ページ' },
        { path: '/rollcall/list/', name: '点呼管理ページ' }
      ]

    # クエリパラメータに年月日の情報がある場合はその年月日で検索
    # ない場合は現在の日にちで検索
      now = Time.now
      @year = params[:year].nil? ? now.year.to_s :  params[:year]
      @month = params[:month].nil? ? now.month.to_s : params[:month]
      erb :'pages/admin/onduty/root'
    end

    namespace '/create' do
      # 当直の作成フォーム
      # クエリパラメータとして年月日を指定する必要あり
      get '/form/' do
        @time = {
          year: params[:year], month: params[:month], date: params[:date]
        }
        # クエリパラメータの年月日が正しくない場合
        redirect '/admin/onduty/' unless MyTime.correct_time?(@time[:year].to_i, @time[:month].to_i, date: @time[:date].to_i)

        @onduty = OndutyModel.get_by_time(@time, is_format: true)
        # 当直がすでにいた場合
        redirect '/admin/onduty/' unless @onduty == {} || @onduty.nil?

        # ログインしているスタッフ
        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        # Webページ内でのリンク
        @links = [
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        # スタッフの一覧
        @staffs = StaffModel.gets_all(is_format: true)[:staffs]
        # 当直作成処理でのエラーメッセージ
        @err = session[:err_msg]
        session[:err_msg] = nil

        erb :'pages/admin/onduty/create_form'
      end

      # 当直作成処理
      # クエリパラメータとして年月日を指定する必要あり
      post '/process/' do
        # 当直の作成処理を当直のControllerを利用して行う
        create_result = OndutyController.create({ staff_id: params[:staff_id], time: {
          year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i
        } })

        # 処理が失敗した場合エラーメッセージと入力データを格納し, 
        # 当直作成フォームにリダイレクトする
        unless create_result[:is_ok]
          session[:err_msg] = create_result[:err][:msg]
          redirect "/admin/onduty/create/form/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}"
        end

        # 処理が成功した場合は当直管理ページにリダイレクトする
        redirect "/admin/onduty/?year=#{params[:year]}&month=#{params[:month]}"
      end
    end

    namespace '/update' do
      # 当直編集フォーム
      # クエリパラメータとして年月日を指定する必要あり
      get '/form/' do
        # 編集したい当直の情報を取得
        @onduty = OndutyModel.get_by_time({
          year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i
          }, is_format: true)
        # 編集したい当直がいなかった場合
        redirect '/admin/onduty/' if @onduty == {} || @onduty.nil?

        # 年月日が正しくない場合
        @time = @onduty[:time]
        redirect '/admin/onduty/' unless MyTime.correct_time?(@time[:year].to_i, @time[:month].to_i, date: @time[:date].to_i)


        # ログインしているスタッフ
        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        # Webページ内でのリンク
        @links = [
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        # 当直の変更処理でのエラーメッセージ
        @err = session[:err_msg]
        session[:err_msg] = nil

        # スタッフの一覧を取得
        @staffs = StaffModel.gets_all(is_format: true)[:staffs]

        # 編集したい当直のスタッフID
        @now_staff_id = OndutyModel.get_by_time(@time).staff_id.to_s

        erb :'pages/admin/onduty/update_form'
      end

      # 当直の変更処理
      # クエリパラメータとして年月日を指定する必要あり
      post '/process/' do
        # 当直の変更処理を当直のControllerを利用して行う
        update_result = OndutyController.update({
          year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i
        }, { staff_id: params[:staff_id] })

        # 処理が失敗した場合エラーメッセージと入力データを格納し, 
        # 当直編集フォームにリダイレクトする
        unless update_result[:is_ok]
          session[:err_msg] = update_result[:err][:msg]
          redirect "/admin/onduty/update/form/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}"
        end


        # 処理が成功した場合は当直管理ページにリダイレクトする
        redirect "/admin/onduty/?year=#{params[:year]}&month=#{params[:month]}"
      end
    end
  end
end

# アクセスしようとしたページが見つからなかった場合, 学生ログインフォームにリダイレクトする
not_found do
  redirect '/student/login/form/'
end
