{
    // 使用するDOMを保持
    const dom = {
        room_num: document.getElementById('room_num'),
        room_auto_list: document.getElementById('room_auto_list')
    }

    const xhr = new XMLHttpRequest();

    // 部屋番号の入力が変化した場合
    dom.room_num.onkeyup = () => {
        // 入力補完をクリア
        dom.room_auto_list.innerHTML = '';
        // 部屋番号の入力を取得
        const value = dom.room_num.value;

        // 入力が1文字の場合
        if (value.length === 1) {
            xhr.onreadystatechange = () => {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const response = xhr.response;
                    // 号館の番号と階の番号のセットを取得した件数分入力補完に追加する
                    if (response['floor_count'] > 0) {
                        response['floors'].forEach(floor => {
                            const option_dom = document.createElement('option');
                            option_dom.value = `${value[0]}${floor['floor_num']}`;
                            dom.room_auto_list.appendChild(option_dom);
                        })
                    }
                }
            }
            xhr.open('GET', `http://localhost:4567/api/building/?building=${value[0]}`, true);
            xhr.responseType = 'json';
            xhr.send(null);
        }
        // 入力が2文字の場合
        else if (value.length === 2) {
            xhr.onreadystatechange = () => {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const response = xhr.response;
                    // 部屋番号を取得した件数分入力補完に追加する
                    if (response['room_count'] > 0) {
                        response['rooms'].forEach(floor => {
                            const option_dom = document.createElement('option');
                            option_dom.value = `${value[0]}${value[1]}${`${floor['room_num']}`.padStart(2, '0')}`;
                            dom.room_auto_list.appendChild(option_dom);
                        })
                    }
                }
            }
            xhr.open('GET', `http://localhost:4567/api/floor/?building=${value[0]}&floor=${value[1]}`, true);
            xhr.responseType = 'json';
            xhr.send(null);
        }
        // 入力が2文字の場合
        else if (value.length === 3) {
            xhr.onreadystatechange = () => {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const response = xhr.response;
                    // 部屋番号を取得した件数分入力補完に追加する
                    if (response['room_count'] > 0) {
                        response['rooms'].forEach(floor => {
                            const option_dom = document.createElement('option');
                            option_dom.value = `${value[0]}${value[1]}${`${floor['room_num']}`.padStart(2, '0')}`;
                            dom.room_auto_list.appendChild(option_dom);
                        })
                    }
                }
            }
            xhr.open('GET', `http://localhost:4567/api/room/?building=${value[0]}&floor=${value[1]}&digit_ten=${value[2]}`, true);
            xhr.responseType = 'json';
            xhr.send(null);
        }
    }
}