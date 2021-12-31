{
    // 使用するDOMを保持
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

    // 名前の入力欄からフォーカスが外れたときに名前のバリデーションを行う
    dom.input.user_name.onblur = () => {
        // エラーメッセージをクリア
        dom.error.user_name.textContent = '';
        xhr.onreadystatechange = () => {
            // バリデーションが失敗した場合はエラーメッセージを表示する
            if (xhr.readyState === 4 && xhr.status === 200 && !xhr.response['is_ok'])
                dom.error.user_name.textContent = xhr.response['err']['msg']
        }
        xhr.open('GET', `http://localhost:4567/api/valid/user/name/?name=${dom.input.user_name.value}`, true);
        xhr.responseType = 'json';
        xhr.send(null);
    }
}