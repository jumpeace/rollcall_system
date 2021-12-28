{
    const dom = {
        input: {
            raw_passwd: document.querySelector('input[name=raw_passwd]'),
            config_passwd: document.querySelector('input[name=config_passwd]')
        },
        error: {
            passwd: document.getElementById('passwd_error')
        },
    }
    const item_names = ['email', 'user_name'];
    item_names.forEach(item_name => {
        dom.input[item_name] = document.querySelector(`*[name=${item_name}]`);
        dom.error[item_name] = document.getElementById(`${item_name}_error`);
    })

    const xhr = new XMLHttpRequest();

    dom.input.email.onblur = () => {
        dom.error.email.textContent = '';
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.email.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:9998/api/valid/user/email/?email=${dom.input.email.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    dom.input.user_name.onblur = () => {
        dom.error.user_name.textContent = '';
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                    dom.error.user_name.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:9998/api/valid/user/name/?name=${dom.input.user_name.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    const passwd_ajax = () => {
        dom.error.passwd.textContent = '';
        xhr.onreadystatechange = () => {
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