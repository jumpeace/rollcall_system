require 'sinatra/namespace'
require 'sinatra'

require './controllers/user.rb'
require './helpers/error.rb'
require './helpers/base.rb'
require './controllers/student.rb'
require './controllers/staff.rb'
require './controllers/onduty.rb'
require './valids/user.rb'
require './valids/student.rb'
require './valids/staff.rb'
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
require './env.rb'
require './task.rb'

set :environment, :production
set :sessions,
  expire_after: 7200,
  secret: $session_secret

def staff_login?
  valid_user_token?(session[:user_token], session[:user_id]) && StaffController.staff?(session[:user_id])
end

def admin_staff_login?
  valid_user_token?(session[:user_token], session[:user_id]) && StaffController.admin_staff?(session[:user_id])
end

def normal_staff_login?
  valid_user_token?(session[:user_token], session[:user_id]) && StaffController.normal_staff?(session[:user_id])
end

def onduty_login?(time)
  valid_user_token?(session[:user_token], session[:user_id]) && OndutyController.onduty?(session[:user_id], time)
end

def student_login?
  valid_user_token?(session[:user_token], session[:user_id]) && StudentController.student?(session[:user_id])
end

def anyone_login?
  student_login? || staff_login?
end

def get_default_url
  return '/staff/mypage/' if staff_login?
  return '/student/mypage/' if student_login?

  nil
end

# 初期設定
srand(Time.now.to_i)

# 定期タスク
Thread.start do
  exec_tasks()
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

# Ajaxで呼ぶエンドポイント
namespace '/api' do
  get '/building/' do
    body FloorModel.gets_by_building(params[:building], is_format: true).to_json
  end

  get '/floor/' do
    body RoomModel.gets_by_building_floor(params[:building], params[:floor], is_format: true).to_json
  end

  get '/room/' do
    body RoomModel.gets_by_building_floor_digit_ten(params[:building], params[:floor], params[:digit_ten].to_i, is_format: true).to_json
  end

  # 年月日によって取得する
  get '/onduty/' do
    body OndutyModel.gets_by_year_month(params[:year].to_i, params[:month].to_i, is_format: true).to_json
  end

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

  namespace '/valid' do
    namespace '/user' do
      get '/email/' do
        body UserValid::Fields.email(params[:email]).to_json
      end
      get '/name/' do
        body UserValid::Fields.name(params[:name]).to_json
      end
      get '/passwd/' do
        body UserValid::Fields.passwd(params[:raw_passwd], params[:config_passwd]).to_json
      end
    end

    namespace '/student' do
      get '/id/' do
        result = { is_ok: false }
        field_result = {}

        field_result[:id] = StudentValid::Fields.id(params[:id])
        if field_result[:id][:is_ok]
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
      get '/grade/' do
        body StudentValid::Fields.grade(params[:grade]).to_json
      end
      get '/department_id/' do
        body StudentValid::Fields.department_id(params[:department_id]).to_json
      end
      get '/room_num/' do
        body StudentValid::Fields.room_num(params[:room_num], id: params[:id]).to_json
      end
    end
  end
end

namespace '/user' do
  namespace '/logout' do
    post '/process/' do
      redirect '/student/login/form/' unless anyone_login?

      session.clear
      redirect '/student/login/form/'
    end
  end
end

namespace '/student' do
  namespace '/login' do
    get '/form/' do
      default_url = get_default_url
      redirect default_url unless default_url.nil?

      @links = [{ path: '/staff/login/form/', name: 'ログインフォーム(スタッフ)' }]

      @err = session[:err_msg]
      @form_data = session[:form_data]
      session[:err_msg] = nil
      session[:form_data] = nil

      erb :'pages/student/login_form'
    end

    post '/process/' do
      login_result = StudentController.login({ id: params[:student_id], passwd: params[:passwd] })

      unless login_result[:is_ok]
        session[:err_msg] = login_result[:err][:msg]
        session[:form_data] = params
        session[:form_data][:passwd] = nil
        redirect '/student/login/form/'
      end

      session[:user_id] = login_result[:data][:user_id]
      session[:user_token] = get_user_token(login_result[:data][:user_id])
      redirect '/student/mypage/'
    end
  end

  get '/mypage/' do
    redirect '/student/login/form/' unless student_login?
    @logined_student = StudentModel.get_by_user_id(session[:user_id], is_format: true)
    @notifies = []
    @links = [{ path: '/rollcall/form/', name: '点呼フォーム' }]

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
  namespace '/login' do
    get '/form/' do
      default_url = get_default_url
      redirect default_url unless default_url.nil?

      @notifies = []
      @links = [{ path: '/student/login/form/', name: 'ログインフォーム(学生)' }]

      @err = session[:err_msg]
      @form_data = session[:form_data]
      session[:err_msg] = nil
      session[:form_data] = nil

      erb :'pages/staff/login_form'
    end

    post '/process/' do
      login_result = StaffController.login({ email: params[:email], passwd: params[:passwd] })

      unless login_result[:is_ok]
        session[:err_msg] = login_result[:err][:msg]
        session[:form_data] = params
        session[:form_data][:passwd] = nil
        redirect '/staff/login/form/'
      end

      session[:user_id] = login_result[:data][:user_id]
      session[:user_token] = get_user_token(login_result[:data][:user_id])
      redirect '/staff/mypage/'
    end
  end

  get '/mypage/' do
    redirect '/staff/login/form/' unless staff_login?

    @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
    @notifies = []
    # TODO 当直の時以外は点呼ページのボタンを押せないようにする
    @links = [{ path: '/rollcall/list/', name: '点呼管理ページ' }]

    @links.push({ path: '/admin/', name: '管理者ページ' }) if admin_staff_login?

    now = Time.now
    @notifies.push('今日は当直です。') if OndutyController.onduty?(session[:user_id], {
      year: now.year, month: now.month, date: now.day
    })

    @onduties = OndutyModel.gets_by_staff_now_future(@logined_staff[:id], is_format: true)[:onduties]

    erb :'pages/staff/mypage'
  end
end

namespace '/rollcall' do
  get '/form/' do
    redirect '/student/login/form/' unless student_login?

    session[:referrer] = request.path
    # 点呼時間内でない場合
    redirect '/rollcall/unable/' unless RollcallController.able_rollcall?

    @logined_student = StudentModel.get_by_user_id(session[:user_id], is_format: true)

    # 点呼済の場合
    redirect '/rollcall/done/' if RollcallController.rollcall_today_student_done?(@logined_student[:id])

    @links = []

    @student_id = @logined_student[:id]

    @err = session[:err_msg]
    session[:err_msg] = nil

    rollcall_time = RollcallController.rollcalling_time
    @start_time = MyTime.str(rollcall_time[:start])
    @due_time = MyTime.str(rollcall_time[:due])

    erb :'pages/rollcall/form'
  end

  post '/process/' do
    redirect '/student/login/form/' unless student_login?

    student = StudentModel.get_by_user_id(session[:user_id], is_format: true)
    rollcall_result = RollcallController.rollcall_today_by_student(student[:id], { student_img: params[:student_img] })

    unless rollcall_result[:is_ok]
      session[:err_msg] = rollcall_result[:err][:msg]
      redirect '/rollcall/form/'
    end

    redirect '/rollcall/done/'
  end

  get '/unable/' do
    redirect '/student/login/form/' unless student_login?

    # '/rollcall/form/' からリダイレクトされていない場合ははじく
    is_valid = !session[:referrer].nil? && session[:referrer] == '/rollcall/form/'
    session[:referrer] = nil
    redirect '/rollcall/form/' unless is_valid

    @logined_student = StudentModel.get_by_user_id(session[:user_id], is_format: true)
    @links = []

    rollcall_time = RollcallController.rollcalling_time
    @start_time = MyTime.str(rollcall_time[:start])
    @due_time = MyTime.str(rollcall_time[:due])

    erb :'pages/rollcall/unable'
  end

  get '/done/' do
    redirect '/student/login/form/' unless student_login?

    is_valid = !session[:referrer].nil? && session[:referrer] == '/rollcall/form/'
    session[:referrer] = nil
    redirect '/rollcall/form/' unless is_valid

    @logined_student = StudentModel.get_by_user_id(session[:user_id], is_format: true)
    @links = []

    @mes = nil
    @mes = '点呼確認待ちです' if RollcallController.rollcall_today_student_done?(@logined_student[:id])
    @mes = '点呼が完了しました' if RollcallController.rollcall_today_onduty_done?(@logined_student[:id])

    redirect '/rollcall/form/' if @mes.nil?

    erb :'pages/rollcall/done'
  end

  # 以下スタッフしかアクセス不可能
  get '/list/' do
    redirect '/staff/login/form/' unless staff_login?

    @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
    @links = [
      { path: '/admin/', name: '管理者ページ' },
      { path: '/admin/student/', name: '学生管理ページ' },
      { path: '/admin/staff/', name: 'スタッフ管理ページ' },
      { path: '/admin/onduty/', name: '当直管理ページ' },
    ]

    now = Time.now
    @year = params[:year].nil? ? now.year.to_s :  params[:year]
    @month = params[:month].nil? ? now.month.to_s : params[:month]
    @date = params[:date].nil? ? now.day.to_s : params[:date]

    # テーブルで1番目の階を選ぶ
    # TODO 学生一覧ページにも使用
    # TODO どの階の点呼が終了しているかが分かるようにする
    floors = FloorModel.gets_all(is_format: true)[:floors]
    selected_floor = floors.length.positive? ? floors[0] : nil
    @building_num = params[:building].nil? ?
      (selected_floor.nil? ? '' : selected_floor[:building_num]) : params[:building]
    @floor_num = params[:floor].nil? ?
      (selected_floor.nil? ? '' : selected_floor[:floor_num]) : params[:floor]
    @errs = session[:err_msgs].nil? ? [] : session[:err_msgs]
    session[:err_msgs] = nil

    erb :'pages/rollcall/list'
  end

  post '/check/' do
    redirect '/staff/login/form/' unless staff_login?

    check_result = RollcallController.checks_by_onduty(params[:student_ids].split(','), {
      year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i,
    })

    unless check_result[:is_ok]
      session[:err_msgs] = []
      check_result[:errs].each do |err|
        session[:err_msgs].push(err[:msg])
      end
      redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
    end

    redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
  end

  post '/forcedcheck/' do
    redirect '/staff/login/form/' unless staff_login?

    forcedcheck_result = RollcallController.forcedchecks_by_onduty(params[:student_ids].split(','), {
      year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i,
    })

    unless forcedcheck_result[:is_ok]
      session[:err_msgs] = []
      forcedcheck_result[:errs].each do |err|
        session[:err_msgs].push(err[:msg])
      end
      redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
    end

    redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
  end

  post '/startover/' do
    redirect '/staff/login/form/' unless staff_login?

    startover_result = RollcallController.startovers_by_onduty(params[:student_ids].split(','), {
      year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i,
    })

    unless startover_result[:is_ok]
      session[:err_msgs] = []
      startover_result[:errs].each do |err|
        session[:err_msgs].push(err[:msg])
      end
      redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
    end

    redirect "/rollcall/list/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}&building=#{params[:building]}&floor=#{params[:floor]}"
  end
end

namespace '/admin' do
  before do
    redirect '/staff/login/form/' unless admin_staff_login?
  end

  get '/' do
    @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
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
      @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
      @links = [
        { path: '/admin/', name: '管理者ページ' },
        { path: '/admin/staff/', name: 'スタッフ管理ページ' },
        { path: '/admin/onduty/', name: '当直管理ページ' },
        { path: '/rollcall/list/', name: '点呼管理ページ' }
      ]

      @students = StudentModel.gets_all(is_format: true)[:students]

      @msg = session[:msg]
      session[:msg] = nil

      @err = session[:err_msg]
      session[:err_msg] = nil

      erb :'pages/admin/student/root'
    end

    # 学生の削除
    post '/delete/process/' do
      delete_result = StudentController.deletes(params[:student_ids].split(','))

      unless delete_result[:is_ok]
        session[:err_msg] = delete_result[:err][:msg]
        redirect '/admin/student/'
      end

      session[:msg] = '学生の削除に成功しました'
      redirect '/admin/student/'
    end

    namespace '/create' do
      get '/form/' do
        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        @links = [
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/admin/onduty/', name: '当直管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        @departments = DepartmentModel.gets_all(is_format: true)[:departments]

        @err = session[:err_msg]
        session[:err_msg] = nil
        @msg = session[:msg]
        session[:msg] = nil
        @form_data = session[:form_data]
        session[:form_data] = nil

        erb :'pages/admin/student/create_form'
      end

      post '/process/' do
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

        unless create_result[:is_ok]
          session[:err_msg] = create_result[:err][:msg]
          session[:form_data] = params
          session[:form_data][:student_img] = nil
          session[:form_data][:raw_passwd] = nil
          session[:form_data][:config_passwd] = nil
          redirect '/admin/student/create/form/'
        end

        session[:msg] = '学生の作成に成功しました。'
        redirect '/admin/student/create/form/'
      end
    end

    # 学生更新フォーム
    namespace '/update' do
      get '/:student_id/form/' do
        get_result = StudentModel.get_by_id(params[:student_id])
        redirect '/admin/student/' if get_result.nil?

        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        @links = [
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/admin/onduty/', name: '当直管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        get_result_by_format = StudentModel.get_by_id(params[:student_id], is_format: true)
        get_result_by_record = StudentModel.get_by_id(params[:student_id])
        redirect '/admin/student/' if get_result_by_format.nil?

        form_data_by_get_result = {
          user_name: get_result_by_format[:user][:name],
          grade: get_result_by_format[:grade],
          department_id: get_result_by_record.department_id,
          room_num: get_result_by_format[:room][:room]
        }

        @departments = DepartmentModel.gets_all(is_format: true)[:departments]

        @student_id = params[:student_id]
        @err = session[:err_msg]
        session[:err_msg] = nil
        @form_data = session[:form_data].nil? ? form_data_by_get_result : session[:form_data]
        session[:form_data] = nil

        erb :'pages/admin/student/update_form'
      end

      post '/:student_id/process/' do
        update_result = StudentController.update(params[:student_id].to_i, {
            user_name: params[:user_name],
            grade: params[:grade],
            department_id: params[:department_id],
            room_num: params[:room_num]
          })

        unless update_result[:is_ok]
          session[:err_msg] = update_result[:err][:msg]

          redirect '/admin/student/' if update_result[:err][:type] == $err_types[:NOT_FOUND]

          session[:form_data] = params
          redirect "/admin/student/update/#{params[:student_id]}/form/"
        end

        session[:update_student_mes] = '学生の更新に成功しました。'
        redirect '/admin/student/'
      end
    end

    namespace '/passwd' do
      namespace '/update' do
        get '/:student_id/form/' do
          get_result = StudentModel.get_by_id(params[:student_id])
          redirect '/admin/student/' if get_result.nil?

          @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
          @links = [
            { path: '/admin/student/', name: '学生管理ページ' },
            { path: '/admin/', name: '管理者ページ' },
            { path: '/admin/staff/', name: 'スタッフ管理ページ' },
            { path: '/admin/onduty/', name: '当直管理ページ' },
            { path: '/rollcall/list/', name: '点呼管理ページ' }
          ]

          @student_id = params[:student_id]
          @err = session[:err_msg]
          session[:err_msg] = nil

          erb :'pages/admin/student/update_passwd_form'
        end

        post '/:student_id/process/' do
          update_result = StudentController.update_passwd(params[:student_id],
            { now_passwd: params[:now_passwd], new_passwd: params[:new_passwd] })

          unless update_result[:is_ok]
            redirect '/admin/student/' if update_result[:err][:type] == $err_types[:NOT_FOUND]

            session[:err_msg] = update_result[:err][:msg]
            redirect "/admin/student/passwd/update/#{params[:student_id]}/form/"
          end

          session[:update_student_passwd_mes] = 'パスワード変更に成功しました。'
          redirect '/admin/student/'
        end
      end
    end
  end

  namespace '/staff' do
    # スタッフ一覧表示ページ
    get '/' do
      @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
      @links = [
        { path: '/admin/', name: '管理者ページ' },
        { path: '/admin/student/', name: '学生管理ページ' },
        { path: '/admin/onduty/', name: '当直管理ページ' },
        { path: '/rollcall/list/', name: '点呼管理ページ' }
      ]

      @staffs = StaffModel.gets_all(is_format: true)[:staffs]

      @msg = session[:msg]
      session[:msg] = nil

      @errs = []
      @errs = session[:err_msgs] unless session[:err_msgs].nil?
      session[:err_msgs] = nil

      @errs.push(session[:err_msg]) unless session[:err_msg].nil?
      session[:err_msg] = nil

      erb :'pages/admin/staff/root'
    end

    # スタッフの削除
    post '/delete/process/' do
      delete_result = StaffController.deletes(params[:staff_ids].split(','))

      unless delete_result[:is_ok]
        session[:err_msgs] = []
        delete_result[:errs].each do |err|
          session[:err_msgs].push(err[:msg])
        end
        redirect '/admin/staff/'
      end

      session[:msg] = 'スタッフの削除に成功しました'
      redirect '/admin/staff/'
    end

    namespace '/normal/create' do
      get '/form/' do
        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        @links = [
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/onduty/', name: '当直管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        @msg = session[:msg]
        session[:msg] = nil
        @err = session[:err_msg]
        session[:err_msg] = nil
        @form_data = session[:form_data]
        session[:form_data] = nil

        erb :'pages/admin/staff/normal_create_form'
      end

      post '/process/' do
        create_result = StaffController.create_normal({
            email: params[:email],
            user_name: params[:user_name],
            raw_passwd: params[:raw_passwd],
            config_passwd: params[:config_passwd]
          })

        unless create_result[:is_ok]
          session[:err_msg] = create_result[:err][:msg]
          session[:form_data] = params
          session[:form_data][:raw_passwd] = nil
          session[:form_data][:config_passwd] = nil
          redirect '/admin/staff/normal/create/form/'
        end

        session[:msg] = 'スタッフの作成に成功しました。'
        redirect '/admin/staff/normal/create/form/'
      end
    end

    # スタッフ更新フォーム
    namespace '/update' do
      get '/:staff_id/form/' do
        get_result = StaffModel.get_by_id(params[:staff_id], is_format: true)
        redirect '/admin/staff/' if get_result.nil?

        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        @links = [
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/onduty/', name: '当直管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        form_data_by_get_result = {
          email: get_result[:user][:email],
          user_name: get_result[:user][:name],
        }

        @staff_id = params[:staff_id]
        @err = session[:err_msg]
        session[:err_msg] = nil
        @form_data = session[:form_data].nil? ? form_data_by_get_result : session[:form_data]
        session[:form_data] = nil

        erb :'pages/admin/staff/update_form'
      end

      post '/:staff_id/process/' do
        update_result = StaffController.update(params[:staff_id], {
            user_name: params[:user_name]
          })

        unless update_result[:is_ok]
          redirect '/admin/staff/' if update_result[:err][:type] == $err_types[:NOT_FOUND]

          session[:err_msg] = update_result[:err][:msg]
          session[:form_data] = params
          redirect "/admin/staff/update/#{params[:staff_id]}/form/"
        end

        session[:update_staff_mes] = 'スタッフの更新に成功しました。'
        redirect '/admin/staff/'
      end
    end

    namespace '/passwd' do
      namespace '/update' do
        get '/:staff_id/form/' do
          get_result = StaffModel.get_by_id(params[:staff_id], is_format: true)
          redirect '/admin/student/' if get_result.nil?

          @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
          @links = [
            { path: '/admin/staff/', name: 'スタッフ管理ページ' },
            { path: '/admin/', name: '管理者ページ' },
            { path: '/admin/student/', name: '学生管理ページ' },
            { path: '/admin/onduty/', name: '当直管理ページ' },
            { path: '/rollcall/list/', name: '点呼管理ページ' }
          ]

          @staff = get_result
          p @staff
          @err = session[:err_msg]
          session[:err_msg] = nil

          erb :'pages/admin/staff/update_passwd_form'
        end

        post '/:staff_id/process/' do
          update_result = StaffController.update_passwd(params[:staff_id],
          { now_passwd: params[:now_passwd], new_passwd: params[:new_passwd]} )

          unless update_result[:is_ok]
            redirect '/admin/staff/' if update_result[:err][:type] == $err_types[:NOT_FOUND]

            session[:err_msg] = update_result[:err][:msg]
            redirect "/admin/staff/passwd/update/#{params[:staff_id]}/form/"
          end

          session[:update_staff_passwd_mes] = 'パスワード変更に成功しました'
          redirect '/admin/staff/'
        end
      end
    end
  end

  namespace '/onduty' do
    get '/' do
      @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
      @links = [
        { path: '/admin/', name: '管理者ページ' },
        { path: '/admin/student/', name: '学生管理ページ' },
        { path: '/admin/staff/', name: 'スタッフ管理ページ' },
        { path: '/rollcall/list/', name: '点呼管理ページ' }
      ]

      now = Time.now
      @year = params[:year].nil? ? now.year.to_s :  params[:year]
      @month = params[:month].nil? ? now.month.to_s : params[:month]
      erb :'pages/admin/onduty/root'
    end

    namespace '/create' do
      get '/form/' do
        @time = {
          year: params[:year], month: params[:month], date: params[:date]
        }
        redirect '/admin/onduty/' unless MyTime.correct_time?(@time[:year].to_i, @time[:month].to_i, date: @time[:date].to_i)

        @onduty = OndutyModel.get_by_time(@time, is_format: true)

        redirect '/admin/onduty/' unless @onduty == {} || @onduty.nil?

        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        @links = [
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        @staffs = StaffModel.gets_all(is_format: true)[:staffs]
        @err = session[:err_msg]
        session[:err_msg] = nil

        erb :'pages/admin/onduty/create_form'
      end

      post '/process/' do
        create_result = OndutyController.create({ staff_id: params[:staff_id], time: {
          year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i
        } })

        unless create_result[:is_ok]
          session[:err_msg] = create_result[:err][:msg]
          redirect "/admin/onduty/create/form/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}"
        end

        redirect "/admin/onduty/?year=#{params[:year]}&month=#{params[:month]}"
      end
    end

    namespace '/update' do
      get '/form/' do
        @onduty = OndutyModel.get_by_time({
           year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i
          }, is_format: true)
        redirect '/admin/onduty/' if @onduty == {} || @onduty.nil?
        @time = @onduty[:time]
        redirect '/admin/onduty/' unless MyTime.correct_time?(@time[:year].to_i, @time[:month].to_i, date: @time[:date].to_i)


        @logined_staff = StaffModel.get_by_user_id(session[:user_id], is_format: true)
        @links = [
          { path: '/admin/', name: '管理者ページ' },
          { path: '/admin/student/', name: '学生管理ページ' },
          { path: '/admin/staff/', name: 'スタッフ管理ページ' },
          { path: '/rollcall/list/', name: '点呼管理ページ' }
        ]

        @err = session[:err_msg]
        session[:err_msg] = nil
        @staffs = StaffModel.gets_all(is_format: true)[:staffs]

        @now_staff_id = OndutyModel.get_by_time(@time).staff_id.to_s

        erb :'pages/admin/onduty/update_form'
      end

      post '/process/' do
        update_result = OndutyController.update({
          year: params[:year].to_i, month: params[:month].to_i, date: params[:date].to_i
        }, { staff_id: params[:staff_id] })

        unless update_result[:is_ok]
          session[:err_msg] = update_result[:err][:msg]
          redirect "/admin/onduty/update/form/?year=#{params[:year]}&month=#{params[:month]}&date=#{params[:date]}"
        end

        redirect "/admin/onduty/?year=#{params[:year]}&month=#{params[:month]}"
      end
    end
  end
end

# not_found do
#   redirect '/student/login/form'
# end
