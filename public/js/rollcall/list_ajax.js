{
    // 使用するDOMを保持
    const dom = {
        input: {
            building_num: document.querySelector('input[name=building_num]'),
            floor_num: document.querySelector('input[name=floor_num]'),
            year: document.querySelector('input[name=year]'),
            month: document.querySelector('input[name=month]'),
            date: document.querySelector('input[name=date]')
        }
    }

    const xhr = new XMLHttpRequest();

    // タグ名とテキストからDOMを生成する
    const createDom = (tagName, html) => {
        const dom = document.createElement(tagName);
        dom.innerHTML = html ?? '';
        return dom;
    }

    // 年月日と号館と階で当直を検索
    const search = () => {
        // 号館の検索条件
        const building_num = dom.input.building_num.value;
        // 階の検索条件
        const floor_num = dom.input.floor_num.value;
        // 年の検索条件
        const year = dom.input.year.value;
        // 月の検索条件
        const month = dom.input.month.value;
        // 日の検索条件
        const date = dom.input.date.value;

        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200) {
                // DOMのクリア
                document.querySelector('tbody').innerHTML = '';

                // 取得した件数分の学生の情報をDOMに追加する
                xhr.response.students.forEach(student => {
                    console.log(student)
                    const trDDom = document.createElement('tr');
                    trDDom.appendChild(createDom('td', '<input type="checkbox">'));
                    trDDom.appendChild(createDom('td', student.room.room));
                    trDDom.appendChild(createDom('td', student.id))
                    trDDom.appendChild(createDom('td', student.grade));
                    trDDom.appendChild(createDom('td', student.department.omit_name));
                    trDDom.appendChild(createDom('td', student.user.name));
                    // 学生の画像があるときはその画像を表示し, ないときは何も表示しない
                    trDDom.appendChild(createDom('td',
                    student.img_name ? `<img src="http://localhost:4567/files/student/${student.img_name}" style="height: 100px; width: auto;">` : ''));
                    // 点呼時の学生の画像があるときはその画像を表示し, ないときは何も表示しない
                    trDDom.appendChild(createDom('td',
                        student.rollcall.student_img_name ? `<img src="http://localhost:4567/files/rollcall/${student.rollcall.student_img_name}" style="height: 100px; width: auto;">` : ''));
                    trDDom.appendChild(createDom('td',
                        student.rollcall !== undefined ? (student.rollcall.is_student_done ? '○' : '×') : ''));
                    trDDom.appendChild(createDom('td',
                        student.rollcall !== undefined ? (student.rollcall.is_onduty_done ? '○' : '×') : ''));
                    document.querySelector('tbody').appendChild(trDDom);
                })
            }
        }
        xhr.open('GET',
          `http://localhost:4567/api/rollcall/?building=${building_num}&floor=${floor_num}&year=${year}&month=${month}&&date=${date}`,
        true);
        xhr.responseType = 'json';
        xhr.send(null);
    }

    // ページを読み込んだときの初期検索
    search();
    // 検索条件を変えたときの検索
    dom.input.building_num.onkeyup = () => search();
    dom.input.floor_num.onkeyup = () => search();
    dom.input.year.onkeyup = () => search();
    dom.input.month.onkeyup = () => search();
    dom.input.date.onkeyup = () => search();
}