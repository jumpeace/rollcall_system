{
    const dom = {
        video: document.getElementById('camera'),
        canvas: document.getElementById('picture'),
        shutterBtn: document.getElementById('shutter'),
        fileInput: document.getElementById('student_img'),
        rollcallBtn: document.getElementById('rollcall_btn'),
    }

    /** カメラ設定 */
    const setting = {
        audio: false,
        video: {
            width: 300,
            height: 200,
            facingMode: 'user'   // フロントカメラを利用する
        }
    };

    /**
     * カメラを<video>と同期
     */
    navigator.mediaDevices.getUserMedia(setting)
        .then( (stream) => {
            dom.video.srcObject = stream;
            dom.video.onloadedmetadata = (e) => dom.video.play();
    })

    /**
     * シャッターボタン
     */
    dom.shutterBtn.addEventListener('click', () => {
        const ctx = dom.canvas.getContext('2d');

        dom.video.pause();  // 映像を停止
        setTimeout(() => dom.video.play(), 500);

        // canvasに画像を貼り付ける
        ctx.drawImage(dom.video, 0, 0, dom.canvas.width, dom.canvas.height);

        dom.canvas.toBlob((blob) => {
            const file = new File([blob], 'a.png');
            const dt = new DataTransfer();
            dt.items.add(file);
            // document.getElementById('student_img').files = dt.files;
            dom.fileInput.files = dt.files;
            dom.rollcallBtn.style.display = 'block';
        });
    });
}
