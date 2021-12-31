{
    
    class MyTime {
        // 閏年であるか判定
        static isLeapYear(year) {
            return (year % 4) === 0 && (year % 100 !== 0 || (year % 400) === 0 );
        }
    
        // 月が正しいか判定
        static isCorrectMonth(month) {
            return month >= 1 && month <= 12;
        }
    
        // 任意の年月の日数を取得する
        static getMdayNum(year, month) {
            if (!MyTime.isCorrectMonth(month))
                return 0
            if (month === 2)
                return MyTime.isLeapYear(year) ? 29 : 28
            return [31, null, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
        }
    
        // 正確な時間か判定
        static isCorrectTime(year, month, date = null) {
            if (!MyTime.isCorrectMonth(month))
                return false
            if (date !== null)
            if (!(date >= 1 && date <= MyTime.getMdayNum(year, month)))
            return false
    
            return true
        }
    }
    
    // 使用するDOMを保持
    const dom = {
        input: {
            year: document.querySelector('input[name=year]'),
            month: document.querySelector('input[name=month]')
        }
    }
    
    const xhr = new XMLHttpRequest();
    
    // タグ名, テキスト, IDで新しいDOMを生成する
    const createDom = (tagName, html, id = null) => {
        const dom = document.createElement(tagName);
        dom.innerHTML = html ?? '';
        if (id !== null)
            dom.id = id
        return dom;
    }
    
    // 年月で当直を検索
    const search = () => {
        // 年の検索条件
        const year = dom.input.year.value;
        // 月の検索条件
        const month = dom.input.month.value;
    
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200) {
                // DOMのクリア
                document.querySelector('tbody').innerHTML = '';
    
                // 検索条件の年月が正しかった場合
                if (MyTime.isCorrectTime(parseInt(year, 10), parseInt(month, 10))) {
                    const date_num = MyTime.getMdayNum(parseInt(year, 10), parseInt(month, 10));
    
                    // 指定された年月の日にちの分繰り返す
                    for (let date = 0; date < date_num; date++) {
                        const onduty = xhr.response.onduties.find(onduty => date + 1 === onduty.time.date)
                        // 指定された日の当直がいるかどうかで表示を変える
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
    
    // ページを読み込んだときの初期検索
    search();
    // 検索条件を変えたときの検索
    dom.input.year.onkeyup = () => search();
    dom.input.month.onkeyup = () => search();
}