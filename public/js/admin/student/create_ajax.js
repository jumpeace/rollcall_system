{
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

    dom.input.student_id.onblur = () => {
        dom.error.student_id.textContent = '';
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                dom.error.student_id.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:4567/api/valid/student/id/?id=${dom.input.student_id.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    dom.input.user_name.onblur = () => {
        dom.error.user_name.textContent = '';
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.user_name.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:4567/api/valid/user/name/?name=${dom.input.user_name.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    dom.input.grade.onblur = () => {
        dom.error.grade.textContent = '';
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.grade.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:4567/api/valid/student/grade/?grade=${dom.input.grade.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    dom.input.department_id.onblur = () => {
        dom.error.department_id.textContent = '';
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.department_id.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:4567/api/valid/student/department_id/?department_id=${dom.input.department_id.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    dom.input.room_num.onblur = () => {
        dom.error.room_num.textContent = '';
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.room_num.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:4567/api/valid/student/room_num/?room_num=${dom.input.room_num.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    const passwd_ajax = () => {
        dom.error.passwd.textContent = '';
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.passwd.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:4567/api/valid/user/passwd/?raw_passwd=${dom.input.raw_passwd.value}&config_passwd=${dom.input.config_passwd.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    dom.input.raw_passwd.onblur = () => passwd_ajax();
    dom.input.config_passwd.onblur = () => passwd_ajax();
}