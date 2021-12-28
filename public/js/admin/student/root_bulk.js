const dom = {
    delete_bulk: document.getElementById('delete_bulk'),
    students: document.getElementById('students'),
    studentIdsInput: document.getElementById('student_ids_input'),
}

dom.delete_bulk.onsubmit = (event) => {
    const studentIds = []

    for (let tr of dom.students.childNodes) {
        if (tr.nodeName === '#text') continue;
        const studentId = tr.childNodes.item(3).textContent;
        const isChecked = tr.childNodes.item(1).childNodes.item(0).checked;
        if (isChecked) studentIds.push(studentId);
    }
    dom.studentIdsInput.value = studentIds.join(',');
}