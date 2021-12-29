{
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

    const createDom = (tagName, html) => {
        const dom = document.createElement(tagName);
        dom.innerHTML = html ?? '';
        return dom;
    }

    const search = () => {
        const building_num = dom.input.building_num.value;
        const floor_num = dom.input.floor_num.value;
        const year = dom.input.year.value;
        const month = dom.input.month.value;
        const date = dom.input.date.value;

        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200) {
                // DOMのクリア
                document.querySelector('tbody').innerHTML = '';
                xhr.response.students.forEach(student => {
                    console.log(student)
                    const trDDom = document.createElement('tr');
                    trDDom.appendChild(createDom('td', '<input type="checkbox">'));
                    trDDom.appendChild(createDom('td', student.room.room));
                    trDDom.appendChild(createDom('td', student.id))
                    trDDom.appendChild(createDom('td', student.grade));
                    trDDom.appendChild(createDom('td', student.department.omit_name));
                    trDDom.appendChild(createDom('td', student.user.name));
                    trDDom.appendChild(createDom('td',
                        student.img_name ? `<img src="http://localhost:4567/files/student/${student.img_name}" style="height: 100px; width: auto;">` : ''));
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

    search();
    dom.input.building_num.onkeyup = () => search();
    dom.input.floor_num.onkeyup = () => search();
    dom.input.year.onkeyup = () => search();
    dom.input.month.onkeyup = () => search();
    dom.input.date.onkeyup = () => search();
}