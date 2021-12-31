{
    // 使用するDOMを保持
    const dom = {
        rollcalls: document.getElementById('rollcalls'),
        bulk_button: {
            check: document.getElementById('check_bulk'),
            forcedcheck: document.getElementById('forcedcheck_bulk'),
            startover: document.getElementById('startover_bulk'),
        },
        input: {
            studentIdsCheck: document.getElementById('student_ids_check'),
            studentIdsForcedcheck: document.getElementById('student_ids_forcedcheck'),
            studentIdsStartover: document.getElementById('student_ids_startover')
        }
    }

    // 点呼確認ボタンがクリックされた場合
    dom.bulk_button.check.onsubmit = () => {
        const studentIds = []

        // チェックボックスがチェックされている学籍番号をフォームのデータにカンマ区切りで格納する
        for (let tr of dom.rollcalls.childNodes) {
            if (tr.nodeName === '#text') continue;
            const studentId = tr.childNodes.item(2).textContent;
            const isChecked = tr.childNodes.item(0).childNodes.item(0).checked;
            if (isChecked) studentIds.push(studentId);
        }
        dom.input.studentIdsCheck.value = studentIds.join(',');

        // 処理を行うURLのクエリパラメータを生成
        const year = document.querySelector('*[name=year]').value;
        const month = document.querySelector('*[name=month]').value;
        const date = document.querySelector('*[name=date]').value;
        const building = document.querySelector('*[name=building_num]').value;
        const floor = document.querySelector('*[name=floor_num]').value;
        // yearとmonthは処理後のリダイレクト先に使う
        dom.bulk_button.check.action = `/rollcall/check/?year=${year}&month=${month}&date=${date}&building=${building}&floor=${floor}`
    }

    // 強制点呼確認ボタンがクリックされた場合
    dom.bulk_button.forcedcheck.onsubmit = () => {
        const studentIds = []

        // チェックボックスがチェックされている学籍番号をフォームのデータにカンマ区切りで格納する
        for (let tr of dom.rollcalls.childNodes) {
            if (tr.nodeName === '#text') continue;
            const studentId = tr.childNodes.item(2).textContent;
            const isChecked = tr.childNodes.item(0).childNodes.item(0).checked;
            if (isChecked) studentIds.push(studentId);
        }
        dom.input.studentIdsForcedcheck.value = studentIds.join(',');

        // 処理を行うURLのクエリパラメータを生成
        const year = document.querySelector('*[name=year]').value;
        const month = document.querySelector('*[name=month]').value;
        const date = document.querySelector('*[name=date]').value;
        const building = document.querySelector('*[name=building_num]').value;
        const floor = document.querySelector('*[name=floor_num]').value;
        dom.bulk_button.forcedcheck.action = `/rollcall/forcedcheck/?year=${year}&month=${month}&date=${date}&building=${building}&floor=${floor}`
    }

    // 点呼やり直しボタンがクリックされた場合
    dom.bulk_button.startover.onsubmit = () => {
        const studentIds = []

        // チェックボックスがチェックされている学籍番号をフォームのデータにカンマ区切りで格納する
        for (let tr of dom.rollcalls.childNodes) {
            if (tr.nodeName === '#text') continue;
            const studentId = tr.childNodes.item(2).textContent;
            const isChecked = tr.childNodes.item(0).childNodes.item(0).checked;
            if (isChecked) studentIds.push(studentId);
        }
        dom.input.studentIdsStartover.value = studentIds.join(',');

        // 処理を行うURLのクエリパラメータを生成
        const year = document.querySelector('*[name=year]').value;
        const month = document.querySelector('*[name=month]').value;
        const date = document.querySelector('*[name=date]').value;
        const building = document.querySelector('*[name=building_num]').value;
        const floor = document.querySelector('*[name=floor_num]').value;
        dom.bulk_button.startover.action = `/rollcall/startover/?year=${year}&month=${month}&date=${date}&building=${building}&floor=${floor}`
    }
}