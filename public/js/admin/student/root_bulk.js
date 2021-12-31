{
    // 使用するDOMを保持
    const dom = {
        delete_bulk: document.getElementById('delete_bulk'),
        students: document.getElementById('students'),
        studentIdsInput: document.getElementById('student_ids_input'),
    }
    
    // 学生の一括削除ボタンがクリックされた場合
    dom.delete_bulk.onsubmit = () => {
        const studentIds = []

        // チェックボックスがチェックされている学籍番号をフォームのデータにカンマ区切りで格納する
        for (let tr of dom.students.childNodes) {
            if (tr.nodeName === '#text') continue;
            const studentId = tr.childNodes.item(3).textContent;
            const isChecked = tr.childNodes.item(1).childNodes.item(0).checked;
            if (isChecked) studentIds.push(studentId);
        }
        dom.studentIdsInput.value = studentIds.join(',');
    }
}