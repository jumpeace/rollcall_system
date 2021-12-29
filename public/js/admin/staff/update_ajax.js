{
    const dom = {
        input: {},
        error: {},
    }
    const item_names = ['user_name'];
    item_names.forEach(item_name => {
        dom.input[item_name] = document.querySelector(`*[name=${item_name}]`);
        dom.error[item_name] = document.getElementById(`${item_name}_error`);
    })

    const xhr = new XMLHttpRequest();

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
}