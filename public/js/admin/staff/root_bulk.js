const dom = {
    delete_bulk: document.getElementById('delete_bulk'),
    staffs: document.getElementById('staffs'),
    staffIdsInput: document.getElementById('staff_ids_input'),
}

dom.delete_bulk.onsubmit = (e) => {
    const staffIds = []

    for (let tr of dom.staffs.childNodes) {
        if (tr.nodeName === '#text' || tr.childNodes.item(1).childNodes.length < 2) continue;

        const staffId = tr.childNodes.item(3).textContent;
        const isChecked = tr.childNodes.item(1).childNodes.item(1).checked;
        if (isChecked) staffIds.push(staffId);
    }

    dom.staffIdsInput.value = staffIds.join(',');
}