{
    const dom = {
        room_num: document.getElementById('room_num'),
        room_auto_list: document.getElementById('room_auto_list')
    }

    const xhr = new XMLHttpRequest();

    dom.room_num.onkeyup = () => {
        dom.room_auto_list.innerHTML = '';
        const value = dom.room_num.value;
        if (value.length === 1) {
            xhr.onreadystatechange = () => {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const response = xhr.response;
                    if (response['floor_count'] > 0) {
                        response['floors'].forEach(floor => {
                            const option_dom = document.createElement('option');
                            option_dom.value = `${value[0]}${floor['floor_num']}`;
                            dom.room_auto_list.appendChild(option_dom);
                        })
                    }
                }
            }
            xhr.open('GET', `http://localhost:9998/api/building/?building=${value[0]}`, true);
            xhr.responseType = 'json';
            xhr.send(null);
        }
        else if (value.length === 2) {
            xhr.onreadystatechange = () => {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const response = xhr.response;
                    if (response['room_count'] > 0) {
                        response['rooms'].forEach(floor => {
                            const option_dom = document.createElement('option');
                            option_dom.value = `${value[0]}${value[1]}${`${floor['room_num']}`.padStart(2, '0')}`;
                            dom.room_auto_list.appendChild(option_dom);
                        })
                    }
                }
            }
            xhr.open('GET', `http://localhost:9998/api/floor/?building=${value[0]}&floor=${value[1]}`, true);
            xhr.responseType = 'json';
            xhr.send(null);
        }
        else if (value.length === 3) {
            xhr.onreadystatechange = () => {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    const response = xhr.response;
                    if (response['room_count'] > 0) {
                        response['rooms'].forEach(floor => {
                            const option_dom = document.createElement('option');
                            option_dom.value = `${value[0]}${value[1]}${`${floor['room_num']}`.padStart(2, '0')}`;
                            dom.room_auto_list.appendChild(option_dom);
                        })
                    }
                }
            }
            xhr.open('GET', `http://localhost:9998/api/room/?building=${value[0]}&floor=${value[1]}&digit_ten=${value[2]}`, true);
            xhr.responseType = 'json';
            xhr.send(null);
        }
    }
}