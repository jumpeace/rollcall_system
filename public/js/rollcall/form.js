{
    // 使用するDOMを保持
    const dom = {
        video: document.getElementById('camera'),
        canvas: document.getElementById('picture'),
        shutterBtn: document.getElementById('shutter'),
        fileInput: document.getElementById('student_img'),
        rollcallBtn: document.getElementById('rollcall_btn'),
    }

    // カメラ設定の設定
    const setting = {
        audio: false,
        video: {
            width: 300,
            height: 200,
            facingMode: 'user'
        }
    };

    // カメラをビデオと同期
    navigator.mediaDevices.getUserMedia(setting)
        .then( (stream) => {
            dom.video.srcObject = stream;
            dom.video.onloadedmetadata = (e) => dom.video.play();
    })

    // シャッターボタンが押された場合
    dom.shutterBtn.addEventListener('click', () => {
        // canvasのコンテキスト要素を取得
        const ctx = dom.canvas.getContext('2d');

        // 映像を500ミリ秒停止
        dom.video.pause();  
        setTimeout(() => dom.video.play(), 500);

        // canvasに画像を貼り付ける
        ctx.drawImage(dom.video, 0, 0, dom.canvas.width, dom.canvas.height);

        // canvasを利用してファイルの入力欄に画像を挿入する
        dom.canvas.toBlob((blob) => {
            const file = new File([blob], 'a.png');
            const dt = new DataTransfer();
            dt.items.add(file);
            dom.fileInput.files = dt.files;

            // 点呼ボタンを表示する
            dom.rollcallBtn.style.display = 'block';
        });
    });
}
