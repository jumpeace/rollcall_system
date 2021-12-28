{
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

    dom.bulk_button.check.onsubmit = () => {
        const studentIds = []

        for (let tr of dom.rollcalls.childNodes) {
            if (tr.nodeName === '#text') continue;
            const studentId = tr.childNodes.item(2).textContent;
            const isChecked = tr.childNodes.item(0).childNodes.item(0).checked;
            if (isChecked) studentIds.push(studentId);
        }
        dom.input.studentIdsCheck.value = studentIds.join(',');

        const year = document.querySelector('*[name=year]').value;
        const month = document.querySelector('*[name=month]').value;
        const date = document.querySelector('*[name=date]').value;
        const building = document.querySelector('*[name=building_num]').value;
        const floor = document.querySelector('*[name=floor_num]').value;
        // yearとmonthは処理後のリダイレクト先に使う
        dom.bulk_button.check.action = `/rollcall/check/?year=${year}&month=${month}&date=${date}&building=${building}&floor=${floor}`
    }

    dom.bulk_button.forcedcheck.onsubmit = () => {
        const studentIds = []

        for (let tr of dom.rollcalls.childNodes) {
            if (tr.nodeName === '#text') continue;
            const studentId = tr.childNodes.item(2).textContent;
            const isChecked = tr.childNodes.item(0).childNodes.item(0).checked;
            if (isChecked) studentIds.push(studentId);
        }
        dom.input.studentIdsForcedcheck.value = studentIds.join(',');

        const year = document.querySelector('*[name=year]').value;
        const month = document.querySelector('*[name=month]').value;
        const date = document.querySelector('*[name=date]').value;
        const building = document.querySelector('*[name=building_num]').value;
        const floor = document.querySelector('*[name=floor_num]').value;
        // yearとmonthは処理後のリダイレクト先に使う
        dom.bulk_button.forcedcheck.action = `/rollcall/forcedcheck/?year=${year}&month=${month}&date=${date}&building=${building}&floor=${floor}`
    }

    dom.bulk_button.startover.onsubmit = (e) => {
        // e.preventDefault()
        const studentIds = []

        for (let tr of dom.rollcalls.childNodes) {
            if (tr.nodeName === '#text') continue;
            const studentId = tr.childNodes.item(2).textContent;
            const isChecked = tr.childNodes.item(0).childNodes.item(0).checked;
            if (isChecked) studentIds.push(studentId);
        }
        dom.input.studentIdsStartover.value = studentIds.join(',');

        const year = document.querySelector('*[name=year]').value;
        const month = document.querySelector('*[name=month]').value;
        const date = document.querySelector('*[name=date]').value;
        const building = document.querySelector('*[name=building_num]').value;
        const floor = document.querySelector('*[name=floor_num]').value;
        // yearとmonthは処理後のリダイレクト先に使う
        dom.bulk_button.startover.action = `/rollcall/startover/?year=${year}&month=${month}&date=${date}&building=${building}&floor=${floor}`
        // return false
    }
}