class MyTime {
    static isLeapYear(year) {
        return (year % 4) === 0 && (year % 100 !== 0 || (year % 400) === 0 );
    }

    static isCorrectMonth(month) {
        return month >= 1 && month <= 12;
    }

    static getMdayNum(year, month) {
        if (!MyTime.isCorrectMonth(month))
            return 0
        if (month === 2)
            return MyTime.isLeapYear(year) ? 29 : 28
        return [31, null, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
    }

    static isCorrectTime(year, month, date = null) {
        if (!MyTime.isCorrectMonth(month))
            return false
        if (date !== null)
        if (!(date >= 1 && date <= MyTime.getMdayNum(year, month)))
        return false

        return true
    }
}

const dom = {
    input: {
        year: document.querySelector('input[name=year]'),
        month: document.querySelector('input[name=month]')
    }
}

const xhr = new XMLHttpRequest();

const createDom = (tagName, html, id = null) => {
    const dom = document.createElement(tagName);
    dom.innerHTML = html ?? '';
    if (id !== null)
        dom.id = id
    return dom;
}

const search = () => {
    const year = dom.input.year.value;
    const month = dom.input.month.value;
    xhr.onreadystatechange = () => {
        if (xhr.readyState === 4 && xhr.status === 200) {
            // DOMのクリア
            document.querySelector('tbody').innerHTML = '';

            // TODO 正確な年月日かを確かめる
            if (MyTime.isCorrectTime(parseInt(year, 10), parseInt(month, 10))) {
                // TODO 日にちを検索する関数を作る
                const date_num = MyTime.getMdayNum(parseInt(year, 10), parseInt(month, 10));

                for (let date = 0; date < date_num; date++) {
                    const onduty = xhr.response.onduties.find(onduty => date + 1 === onduty.time.date)
                    const text = onduty ?
                        { user_name: onduty.staff.user.name, email: onduty.staff.user.email,
                            update_link:  `<a href="/admin/onduty/update/form/?year=${year}&month=${month}&date=${date + 1}">変更</a>`} :
                        { user_name: '', email: '',
                            update_link: `<a href="/admin/onduty/create/form/?year=${year}&month=${month}&date=${date + 1}">追加</a>` }

                    const trDDom = document.createElement('tr');
                    trDDom.appendChild(createDom('td', date + 1));
                    trDDom.appendChild(createDom('td', text.user_name));
                    trDDom.appendChild(createDom('td', text.email));
                    trDDom.appendChild(createDom('td', text.update_link));
                    document.querySelector('tbody').appendChild(trDDom);
                }
            }
        }
    }
    xhr.open('GET', `http://localhost:4567/api/onduty/?year=${year}&month=${month}`, true);
    xhr.responseType = 'json';
    xhr.send(null);
}


search();
dom.input.year.onkeyup = () => search();
dom.input.month.onkeyup = () => search();