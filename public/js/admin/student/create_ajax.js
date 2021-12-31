{
    // 使用するDOMを保持
    const dom = {
        input: {
            raw_passwd: document.querySelector('input[name=raw_passwd]'),
            config_passwd: document.querySelector('input[name=config_passwd]')
        },
        error: {
            email: document.getElementById('email_error'),
            passwd: document.getElementById('passwd_error')
        },
    }
    const item_names = ['student_id', 'user_name', 'grade', 'department_id', 'room_num'];
    item_names.forEach(item_name => {
        dom.input[item_name] = document.querySelector(`*[name=${item_name}]`);
        dom.error[item_name] = document.getElementById(`${item_name}_error`);
    })

    const xhr = new XMLHttpRequest();

    // 学籍番号の入力欄からフォーカスが外れたときに学籍番号のバリデーションを行う
    dom.input.student_id.onblur = () => {
        // エラーメッセージをクリア
        dom.error.student_id.textContent = '';
        xhr.onreadystatechange = () => {
            // バリデーションが失敗した場合はエラーメッセージを表示する
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                dom.error.student_id.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:9998/api/valid/student/id/?id=${dom.input.student_id.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    // 名前の入力欄からフォーカスが外れたときに名前のバリデーションを行う
    dom.input.user_name.onblur = () => {
        // エラーメッセージをクリア
        dom.error.user_name.textContent = '';
        xhr.onreadystatechange = () => {
            // バリデーションが失敗した場合はエラーメッセージを表示する
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.user_name.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:9998/api/valid/user/name/?name=${dom.input.user_name.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    // 学年の入力欄からフォーカスが外れたときに学年のバリデーションを行う
    dom.input.grade.onblur = () => {
        // エラーメッセージをクリア
        dom.error.grade.textContent = '';
        xhr.onreadystatechange = () => {
            // バリデーションが失敗した場合はエラーメッセージを表示する
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.grade.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:9998/api/valid/student/grade/?grade=${dom.input.grade.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    // 学科の入力欄からフォーカスが外れたときに学科のバリデーションを行う
    dom.input.department_id.onblur = () => {
        // エラーメッセージをクリア
        dom.error.department_id.textContent = '';
        xhr.onreadystatechange = () => {
            // バリデーションが失敗した場合はエラーメッセージを表示する
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.department_id.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:9998/api/valid/student/department_id/?department_id=${dom.input.department_id.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    // 部屋番号の入力欄からフォーカスが外れたときに部屋番号のバリデーションを行う
    dom.input.room_num.onblur = () => {
        // エラーメッセージをクリア
        dom.error.room_num.textContent = '';
        xhr.onreadystatechange = () => {
            // バリデーションが失敗した場合はエラーメッセージを表示する
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.room_num.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:9998/api/valid/student/room_num/?room_num=${dom.input.room_num.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    // パスワードまたは確認パスワードの入力欄からフォーカスが外れたときにパスワードのバリデーションを行う
    const passwd_ajax = () => {
        // エラーメッセージをクリア
        dom.error.passwd.textContent = '';
        xhr.onreadystatechange = () => {
            // バリデーションが失敗した場合はエラーメッセージを表示する
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.passwd.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:9998/api/valid/user/passwd/?raw_passwd=${dom.input.raw_passwd.value}&config_passwd=${dom.input.config_passwd.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }
    dom.input.raw_passwd.onblur = () => passwd_ajax();
    dom.input.config_passwd.onblur = () => passwd_ajax();
}