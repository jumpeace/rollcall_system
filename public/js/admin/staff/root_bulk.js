{
    // 使用するDOMを保持
    const dom = {
        delete_bulk: document.getElementById('delete_bulk'),
        staffs: document.getElementById('staffs'),
        staffIdsInput: document.getElementById('staff_ids_input'),
    }
    
    // スタッフの一括削除ボタンがクリックされた場合
    dom.delete_bulk.onsubmit = () => {
        const staffIds = []
    
        // チェックボックスがチェックされているスタッフIDをフォームのデータにカンマ区切りで格納する
        for (let tr of dom.staffs.childNodes) {
            if (tr.nodeName === '#text' || tr.childNodes.item(1).childNodes.length < 2) continue;
    
            const staffId = tr.childNodes.item(3).textContent;
            const isChecked = tr.childNodes.item(1).childNodes.item(1).checked;
            if (isChecked) staffIds.push(staffId);
        }
        dom.staffIdsInput.value = staffIds.join(',');
    }
}