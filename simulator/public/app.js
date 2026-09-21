/* ==========================================================================
   LAICHYM iOS 18 Simulator - Master Controller (app.js)
   ========================================================================== */

(function () {
  'use strict';

  // State Management
  const state = {
    isRecording: false,
    isLiveStreaming: false,
    isFaceCamActive: false,
    isVIP: false,
    activeTab: 'pageHome',
    selectedPlatform: 'youtube',
    recordDuration: 0,
    liveDuration: 0,
    recordTimer: null,
    liveTimer: null,
    mediaRecorder: null,
    recordedChunks: [],
    faceCamStream: null,
    screenStream: null,
    recordings: [
      {
        id: 'rec-demo-1',
        title: 'Gameplay Liên Quân Mobile Highlight',
        duration: 45,
        durationStr: '00:45',
        sizeStr: '18.4 MB',
        resolution: '1080p',
        fps: 60,
        date: '21/09/2026, 11:20',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'
      },
      {
        id: 'rec-demo-2',
        title: 'Hướng dẫn mẹo chụp ảnh iOS 18',
        duration: 128,
        durationStr: '02:08',
        sizeStr: '42.1 MB',
        resolution: '1080p',
        fps: 60,
        date: '20/09/2026, 18:35',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4'
      }
    ],
    activeVideoItem: null
  };

  // DOM Elements Cache
  const el = {
    // Dynamic Island & Status Bar
    statusTime: document.getElementById('statusTime'),
    dynamicIsland: document.getElementById('dynamicIsland'),
    islandText: document.getElementById('islandText'),
    islandTimer: document.getElementById('islandTimer'),
    islandRecDot: document.getElementById('islandRecDot'),
    
    // Main Record Card
    btnMainRecord: document.getElementById('btnMainRecord'),
    recordBtnText: document.getElementById('recordBtnText'),
    recordHintText: document.getElementById('recordHintText'),
    statusDot: document.getElementById('statusDot'),
    statusLabel: document.getElementById('statusLabel'),
    heroQualityLabel: document.getElementById('heroQualityLabel'),
    toggleMicBtn: document.getElementById('toggleMicBtn'),
    toggleAudioBtn: document.getElementById('toggleAudioBtn'),
    toggleFacecamBtn: document.getElementById('toggleFacecamBtn'),
    
    // Floating FaceCam
    floatingFaceCam: document.getElementById('floatingFaceCam'),
    facecamVideo: document.getElementById('facecamVideo'),
    btnCloseFaceCam: document.getElementById('btnCloseFaceCam'),
    
    // Nav Tabs & Pages
    tabButtons: document.querySelectorAll('.tab-btn'),
    pages: document.querySelectorAll('.app-page'),
    
    // Recent & Library
    recentVideosContainer: document.getElementById('recentVideosContainer'),
    recCountBadge: document.getElementById('recCountBadge'),
    galleryGrid: document.getElementById('galleryGrid'),
    librarySearchInput: document.getElementById('librarySearchInput'),
    
    // Livestream
    platTabs: document.querySelectorAll('.plat-tab'),
    platHelpTitle: document.getElementById('platHelpTitle'),
    platHelpDesc: document.getElementById('platHelpDesc'),
    rtmpUrlInput: document.getElementById('rtmpUrlInput'),
    rtmpKeyInput: document.getElementById('rtmpKeyInput'),
    btnToggleKeyEye: document.getElementById('btnToggleKeyEye'),
    btnPasteKey: document.getElementById('btnPasteKey'),
    btnTestRtmp: document.getElementById('btnTestRtmp'),
    testConnResult: document.getElementById('testConnResult'),
    btnStartLive: document.getElementById('btnStartLive'),
    btnLiveText: document.getElementById('btnLiveText'),
    liveMonitorCard: document.getElementById('liveMonitorCard'),
    monBitrate: document.getElementById('monBitrate'),
    monTimer: document.getElementById('monTimer'),
    bitrateSlider: document.getElementById('bitrateSlider'),
    bitrateValLabel: document.getElementById('bitrateValLabel'),
    
    // Modals
    modalVideoPlayer: document.getElementById('modalVideoPlayer'),
    modalVideoTitle: document.getElementById('modalVideoTitle'),
    detailVideoElement: document.getElementById('detailVideoElement'),
    metaDuration: document.getElementById('metaDuration'),
    metaRes: document.getElementById('metaRes'),
    metaSize: document.getElementById('metaSize'),
    btnCloseVideoModal: document.getElementById('btnCloseVideoModal'),
    btnDownloadVideo: document.getElementById('btnDownloadVideo'),
    btnEditThisVideo: document.getElementById('btnEditThisVideo'),
    btnDeleteVideo: document.getElementById('btnDeleteVideo'),
    
    modalEditor: document.getElementById('modalEditor'),
    btnCloseEditorModal: document.getElementById('btnCloseEditorModal'),
    editorVideoElement: document.getElementById('editorVideoElement'),
    editorPreviewStage: document.getElementById('editorPreviewStage'),
    editorWatermarkOverlay: document.getElementById('editorWatermarkOverlay'),
    editorWatermarkCheck: document.getElementById('editorWatermarkCheck'),
    trimStart: document.getElementById('trimStart'),
    trimEnd: document.getElementById('trimEnd'),
    trimValuesLabel: document.getElementById('trimValuesLabel'),
    ratioButtons: document.querySelectorAll('.ratio-btn'),
    btnToggleVoiceover: document.getElementById('btnToggleVoiceover'),
    btnExportEditedVideo: document.getElementById('btnExportEditedVideo'),
    exportProgress: document.getElementById('exportProgress'),
    exportBarFill: document.getElementById('exportBarFill'),
    
    modalPaywall: document.getElementById('modalPaywall'),
    btnClosePaywall: document.getElementById('btnClosePaywall'),
    btnSubscribeVIP: document.getElementById('btnSubscribeVIP'),
    btnRestorePurchase: document.getElementById('btnRestorePurchase'),
    pwPlanCards: document.querySelectorAll('.pw-plan-card'),
    vipPromoBanner: document.getElementById('vipPromoBanner'),
    openPaywallFromHeader: document.getElementById('openPaywallFromHeader'),
    openSettingsFromHeader: document.getElementById('openSettingsFromHeader'),
    userTierLabel: document.getElementById('userTierLabel'),
    
    // Right sidebar actions
    triggerWebScreenShare: document.getElementById('triggerWebScreenShare'),
    triggerWebcamFacecam: document.getElementById('triggerWebcamFacecam'),
    triggerOpenEditorModal: document.getElementById('triggerOpenEditorModal'),
    triggerOpenPaywallModal: document.getElementById('triggerOpenPaywallModal'),
    consoleLogs: document.getElementById('consoleLogs'),
    btnClearLog: document.getElementById('btnClearLog')
  };

  // =========================================================================
  // LOGGER HELPER
  // =========================================================================
  function log(message, type = 'info') {
    const entry = document.createElement('div');
    entry.className = `log-entry ${type}`;
    const time = new Date().toLocaleTimeString();
    entry.textContent = `[${time}] ${message}`;
    el.consoleLogs.appendChild(entry);
    el.consoleLogs.scrollTop = el.consoleLogs.scrollHeight;
  }

  // =========================================================================
  // CLOCK & STATUS BAR
  // =========================================================================
  function updateClock() {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    el.statusTime.textContent = `${hours}:${minutes}`;
  }
  setInterval(updateClock, 1000);
  updateClock();

  // =========================================================================
  // NAVIGATION TABS
  // =========================================================================
  function switchTab(targetPageId) {
    state.activeTab = targetPageId;
    el.pages.forEach(page => {
      page.classList.toggle('active', page.id === targetPageId);
    });
    el.tabButtons.forEach(btn => {
      btn.classList.toggle('active', btn.getAttribute('data-target') === targetPageId);
    });
    log(`[Navigation] Chuyển tới màn hình: ${targetPageId}`, 'info');
  }

  el.tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const target = btn.getAttribute('data-target');
      switchTab(target);
    });
  });

  document.getElementById('cardGoLivestream')?.addEventListener('click', () => switchTab('pageLive'));
  document.getElementById('cardGoGuide')?.addEventListener('click', () => switchTab('pageSettings'));
  document.getElementById('openSettingsFromHeader')?.addEventListener('click', () => switchTab('pageSettings'));

  // =========================================================================
  // DYNAMIC ISLAND CONTROLLER
  // =========================================================================
  function updateDynamicIsland(isActive, title, timerText, isLive = false) {
    if (isActive) {
      el.dynamicIsland.classList.add('expanded');
      el.islandText.textContent = title;
      el.islandTimer.textContent = timerText;
      el.islandRecDot.style.background = isLive ? '#34c759' : '#ff3b30';
    } else {
      el.dynamicIsland.classList.remove('expanded');
    }
  }

  // =========================================================================
  // SCREEN RECORDING CONTROLLER (Web Screen Capture + MediaRecorder)
  // =========================================================================
  async function startScreenRecording() {
    log('[ReplayKit] RPSystemBroadcastPickerView kích hoạt.', 'info');
    try {
      // Thực hiện gọi Browser Screen Capture
      const stream = await navigator.mediaDevices.getDisplayMedia({
        video: { cursor: 'always', frameRate: state.isVIP ? 60 : 30 },
        audio: true
      });
      state.screenStream = stream;

      // Xử lý khi người dùng dừng chia sẻ từ thanh trình duyệt
      stream.getVideoTracks()[0].onended = () => {
        stopScreenRecording();
      };

      state.recordedChunks = [];
      const options = { mimeType: 'video/webm; codecs=vp8,opus' };
      state.mediaRecorder = new MediaRecorder(stream, options);

      state.mediaRecorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) {
          state.recordedChunks.push(event.data);
        }
      };

      state.mediaRecorder.onstop = () => {
        finishRecordingProcess();
      };

      state.mediaRecorder.start(1000);
      state.isRecording = true;
      state.recordDuration = 0;

      // Update UI
      el.btnMainRecord.classList.add('is-recording');
      el.recordBtnText.textContent = 'DỪNG GHI';
      el.statusDot.className = 'status-dot recording';
      el.statusLabel.className = 'status-label recording';
      el.statusLabel.textContent = 'ĐANG GHI HÌNH';
      el.recordHintText.textContent = 'Đang ghi toàn màn hình... Nhấn để dừng';

      log('[ReplayKit] Bắt đầu nhận CMSampleBuffer từ màn hình iOS.', 'success');

      // Start Timer
      clearInterval(state.recordTimer);
      state.recordTimer = setInterval(() => {
        state.recordDuration++;
        const mins = String(Math.floor(state.recordDuration / 60)).padStart(2, '0');
        const secs = String(state.recordDuration % 60).padStart(2, '0');
        const timerStr = `${mins}:${secs}`;
        el.statusLabel.textContent = `ĐANG GHI (${timerStr})`;
        updateDynamicIsland(true, 'GHI MÀN HÌNH', timerStr, false);
      }, 1000);

    } catch (err) {
      log(`[ReplayKit] Người dùng hủy hoặc lỗi cấp quyền: ${err.message}`, 'warn');
      // Mô phỏng ghi hình nếu người dùng từ chối quyền màn hình
      simulateScreenRecording();
    }
  }

  function simulateScreenRecording() {
    log('[Simulator] Chuyển sang chế độ giả lập quay màn hình ReplayKit.', 'info');
    state.isRecording = true;
    state.recordDuration = 0;

    el.btnMainRecord.classList.add('is-recording');
    el.recordBtnText.textContent = 'DỪNG GHI';
    el.statusDot.className = 'status-dot recording';
    el.statusLabel.className = 'status-label recording';
    el.statusLabel.textContent = 'ĐANG GHI HÌNH';
    el.recordHintText.textContent = 'Đang ghi hình giả lập... Nhấn để dừng';

    clearInterval(state.recordTimer);
    state.recordTimer = setInterval(() => {
      state.recordDuration++;
      const mins = String(Math.floor(state.recordDuration / 60)).padStart(2, '0');
      const secs = String(state.recordDuration % 60).padStart(2, '0');
      const timerStr = `${mins}:${secs}`;
      el.statusLabel.textContent = `ĐANG GHI (${timerStr})`;
      updateDynamicIsland(true, 'GHI MÀN HÌNH', timerStr, false);
    }, 1000);
  }

  function stopScreenRecording() {
    if (!state.isRecording) return;
    state.isRecording = false;
    clearInterval(state.recordTimer);

    if (state.mediaRecorder && state.mediaRecorder.state !== 'inactive') {
      state.mediaRecorder.stop();
    } else {
      finishRecordingProcess(true);
    }

    if (state.screenStream) {
      state.screenStream.getTracks().forEach(t => t.stop());
      state.screenStream = null;
    }

    // Reset UI
    el.btnMainRecord.classList.remove('is-recording');
    el.recordBtnText.textContent = 'GHI HÌNH';
    el.statusDot.className = 'status-dot ready';
    el.statusLabel.className = 'status-label';
    el.statusLabel.textContent = 'SẴN SÀNG';
    el.recordHintText.textContent = 'Chạm để chọn màn hình quay thử nghiệm thực tế';
    updateDynamicIsland(false);

    log('[ReplayKit] broadcastFinished() - Đã hoàn tất ghi file MP4.', 'success');
  }

  function finishRecordingProcess(isSimulated = false) {
    let videoUrl = '';
    let fileSizeStr = '24.5 MB';

    if (!isSimulated && state.recordedChunks.length > 0) {
      const blob = new Blob(state.recordedChunks, { type: 'video/webm' });
      videoUrl = URL.createObjectURL(blob);
      const mb = (blob.size / (1024 * 1024)).toFixed(1);
      fileSizeStr = `${mb} MB`;
    } else {
      videoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
    }

    const mins = String(Math.floor(state.recordDuration / 60)).padStart(2, '0');
    const secs = String(state.recordDuration % 60).padStart(2, '0');
    const durationFormatted = `${mins}:${secs}`;

    const newRec = {
      id: 'rec-' + Date.now(),
      title: `Clip quay màn hình ${new Date().toLocaleTimeString()}`,
      duration: state.recordDuration || 8,
      durationStr: durationFormatted === '00:00' ? '00:08' : durationFormatted,
      sizeStr: fileSizeStr,
      resolution: state.isVIP ? '1080p' : '720p',
      fps: state.isVIP ? 60 : 30,
      date: new Date().toLocaleDateString('vi-VN') + ', ' + new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }),
      url: videoUrl
    };

    state.recordings.unshift(newRec);
    renderRecordings();
    log(`[StorageManager] Đã lưu video "${newRec.title}" vào App Group.`, 'success');
    alert(`🎉 Đã quay xong! Video được lưu vào Thư viện (${newRec.durationStr} • ${newRec.sizeStr})`);
  }

  el.btnMainRecord.addEventListener('click', () => {
    if (state.isRecording) {
      stopScreenRecording();
    } else {
      startScreenRecording();
    }
  });

  el.triggerWebScreenShare?.addEventListener('click', () => {
    if (!state.isRecording) startScreenRecording();
    else stopScreenRecording();
  });

  // =========================================================================
  // FACECAM CONTROLLER (Webcam PiP)
  // =========================================================================
  async function toggleFaceCam() {
    if (state.isFaceCamActive) {
      stopFaceCam();
    } else {
      await startFaceCam();
    }
  }

  async function startFaceCam() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
      state.faceCamStream = stream;
      el.facecamVideo.srcObject = stream;
      el.floatingFaceCam.style.display = 'block';
      state.isFaceCamActive = true;
      el.toggleFacecamBtn.classList.add('active');
      log('[FaceCamService] Bật AVCaptureSession camera selfie thành công.', 'success');
    } catch (err) {
      log(`[FaceCamService] Không thể truy cập webcam: ${err.message}. Bật giả lập.`, 'warn');
      el.floatingFaceCam.style.display = 'block';
      state.isFaceCamActive = true;
      el.toggleFacecamBtn.classList.add('active');
    }
  }

  function stopFaceCam() {
    if (state.faceCamStream) {
      state.faceCamStream.getTracks().forEach(t => t.stop());
      state.faceCamStream = null;
    }
    el.floatingFaceCam.style.display = 'none';
    state.isFaceCamActive = false;
    el.toggleFacecamBtn.classList.remove('active');
    log('[FaceCamService] Tắt Face-Cam.', 'info');
  }

  el.toggleFacecamBtn.addEventListener('click', toggleFaceCam);
  el.btnCloseFaceCam.addEventListener('click', stopFaceCam);
  el.triggerWebcamFacecam?.addEventListener('click', toggleFaceCam);

  // Draggable FaceCam on iPhone Screen
  (function makeFaceCamDraggable() {
    const box = el.floatingFaceCam;
    let isDragging = false;
    let startX = 0, startY = 0, initialLeft = 0, initialTop = 0;

    box.addEventListener('mousedown', (e) => {
      isDragging = true;
      startX = e.clientX;
      startY = e.clientY;
      initialLeft = box.offsetLeft;
      initialTop = box.offsetTop;
      box.style.cursor = 'grabbing';
    });

    window.addEventListener('mousemove', (e) => {
      if (!isDragging) return;
      const dx = e.clientX - startX;
      const dy = e.clientY - startY;
      box.style.left = `${initialLeft + dx}px`;
      box.style.top = `${initialTop + dy}px`;
    });

    window.addEventListener('mouseup', () => {
      isDragging = false;
      box.style.cursor = 'grab';
    });
  })();

  // Mic & Audio Toggles
  el.toggleMicBtn.addEventListener('click', () => {
    el.toggleMicBtn.classList.toggle('active');
    const on = el.toggleMicBtn.classList.contains('active');
    log(`[ReplayKit] Micro bình luận: ${on ? 'BẬT' : 'TẮT'}`, 'info');
  });

  el.toggleAudioBtn.addEventListener('click', () => {
    el.toggleAudioBtn.classList.toggle('active');
    const on = el.toggleAudioBtn.classList.contains('active');
    log(`[ReplayKit] Âm thanh hệ thống: ${on ? 'BẬT' : 'TẮT'}`, 'info');
  });

  // =========================================================================
  // LIVESTREAM CONTROLLER (RTMP Hub)
  // =========================================================================
  const platformPresets = {
    youtube: {
      title: 'Hướng dẫn YouTube Live',
      desc: 'Vào YouTube Studio > Tạo > Phát trực tiếp. Sao chép Khóa luồng (Stream Key) và dán vào bên dưới.',
      url: 'rtmp://a.rtmp.youtube.com/live2'
    },
    facebook: {
      title: 'Hướng dẫn Facebook Live',
      desc: 'Vào Facebook Live Producer. Chọn "Dùng khoá luồng", sao chép Khóa luồng và dán vào ô bên dưới.',
      url: 'rtmps://live-api-s.facebook.com:443/rtmp'
    },
    twitch: {
      title: 'Hướng dẫn Twitch Live',
      desc: 'Vào Bảng điều khiển tác giả Twitch > Cài đặt > Luồng > Khóa luồng chính.',
      url: 'rtmp://live.twitch.tv/app'
    },
    custom: {
      title: 'Custom RTMP Server',
      desc: 'Nhập URL máy chủ RTMP cá nhân, TikTok Live Studio hoặc Shopee Live.',
      url: ''
    }
  };

  el.platTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      el.platTabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const plat = tab.getAttribute('data-plat');
      state.selectedPlatform = plat;
      const preset = platformPresets[plat];
      el.platHelpTitle.textContent = preset.title;
      el.platHelpDesc.textContent = preset.desc;
      el.rtmpUrlInput.value = preset.url;
      el.testConnResult.style.display = 'none';
      log(`[RTMP] Đã chọn nền tảng ${plat.toUpperCase()}`, 'info');
    });
  });

  el.btnPasteKey?.addEventListener('click', () => {
    el.rtmpKeyInput.value = 'live_streamkey_' + Math.random().toString(36).substring(7);
    log('[RTMP] Đã điền khóa luồng mẫu.', 'info');
  });

  el.btnToggleKeyEye?.addEventListener('click', () => {
    const isPass = el.rtmpKeyInput.type === 'password';
    el.rtmpKeyInput.type = isPass ? 'text' : 'password';
  });

  el.bitrateSlider?.addEventListener('input', (e) => {
    el.bitrateValLabel.textContent = `${e.target.value} kbps`;
  });

  el.btnTestRtmp?.addEventListener('click', () => {
    const url = el.rtmpUrlInput.value;
    if (!url) {
      el.testConnResult.className = 'test-conn-result error';
      el.testConnResult.textContent = '❌ Vui lòng nhập URL máy chủ RTMP';
      return;
    }
    el.testConnResult.className = 'test-conn-result info';
    el.testConnResult.style.display = 'block';
    el.testConnResult.textContent = '⏳ Đang kiểm tra handshake RTMP socket port 1935...';
    log(`[RTMPStreamer] Kiểm tra kết nối tới ${url}...`, 'info');

    setTimeout(() => {
      el.testConnResult.className = 'test-conn-result success';
      el.testConnResult.textContent = '✅ Kết nối máy chủ RTMP thành công (Ping: 28ms)';
      log('[RTMPStreamer] Handshake RTMP hoàn tất, sẵn sàng đẩy luồng.', 'success');
    }, 800);
  });

  el.btnStartLive?.addEventListener('click', () => {
    if (state.isLiveStreaming) {
      // Stop Livestream
      state.isLiveStreaming = false;
      clearInterval(state.liveTimer);
      el.liveMonitorCard.style.display = 'none';
      el.btnLiveText.textContent = 'BẮT ĐẦU PHÁT TRỰC TIẾP';
      el.btnStartLive.style.background = 'linear-gradient(135deg, #ff3b30, #ff9500)';
      updateDynamicIsland(false);
      log('[RTMPStreamer] Đã ngắt kết nối livestream.', 'warn');
    } else {
      // Start Livestream
      state.isLiveStreaming = true;
      state.liveDuration = 0;
      el.liveMonitorCard.style.display = 'flex';
      el.btnLiveText.textContent = 'DỪNG PHÁT TRỰC TIẾP';
      el.btnStartLive.style.background = 'linear-gradient(135deg, #c41e15, #800000)';

      log(`[RTMPStreamer] Bắt đầu stream tới ${el.rtmpUrlInput.value} (${el.bitrateSlider.value} kbps)`, 'success');

      clearInterval(state.liveTimer);
      state.liveTimer = setInterval(() => {
        state.liveDuration++;
        const mins = String(Math.floor(state.liveDuration / 60)).padStart(2, '0');
        const secs = String(state.liveDuration % 60).padStart(2, '0');
        const timerStr = `${mins}:${secs}`;
        el.monTimer.textContent = timerStr;
        el.monBitrate.textContent = `${parseInt(el.bitrateSlider.value) + Math.floor(Math.random() * 50 - 25)} kbps`;
        updateDynamicIsland(true, 'LIVESTREAM', timerStr, true);
      }, 1000);
    }
  });

  // =========================================================================
  // GALLERY & RECORDINGS CONTROLLER
  // =========================================================================
  function renderRecordings() {
    el.recCountBadge.textContent = `${state.recordings.length} video`;

    // Render Recent horizontal carousel in Home
    el.recentVideosContainer.innerHTML = '';
    state.recordings.slice(0, 5).forEach(rec => {
      const item = document.createElement('div');
      item.className = 'video-thumb-item';
      item.innerHTML = `
        <div class="thumb-preview-box">
          <video src="${rec.url}" preload="metadata"></video>
          <span class="thumb-badge-duration">${rec.durationStr}</span>
        </div>
        <div class="thumb-title">${rec.title}</div>
        <div class="thumb-meta">${rec.resolution} • ${rec.sizeStr}</div>
      `;
      item.addEventListener('click', () => openVideoDetail(rec));
      el.recentVideosContainer.appendChild(item);
    });

    // Render Grid in Library Tab
    el.galleryGrid.innerHTML = '';
    const query = el.librarySearchInput.value.toLowerCase();
    const filtered = state.recordings.filter(r => r.title.toLowerCase().includes(query));

    filtered.forEach(rec => {
      const card = document.createElement('div');
      card.className = 'gallery-card';
      card.innerHTML = `
        <div class="gallery-thumb-wrap">
          <video src="${rec.url}" preload="metadata"></video>
          <span class="play-overlay-icon">▶</span>
          <span class="thumb-badge-duration">${rec.durationStr}</span>
        </div>
        <div class="gallery-info">
          <h5>${rec.title}</h5>
          <div class="gallery-meta">${rec.resolution} • ${rec.sizeStr}</div>
        </div>
      `;
      card.addEventListener('click', () => openVideoDetail(rec));
      el.galleryGrid.appendChild(card);
    });
  }

  el.librarySearchInput?.addEventListener('input', renderRecordings);

  function openVideoDetail(rec) {
    state.activeVideoItem = rec;
    el.modalVideoTitle.textContent = rec.title;
    el.detailVideoElement.src = rec.url;
    el.metaDuration.textContent = rec.durationStr;
    el.metaRes.textContent = `${rec.resolution} (${rec.fps} FPS)`;
    el.metaSize.textContent = rec.sizeStr;
    el.modalVideoPlayer.style.display = 'flex';
    el.detailVideoElement.play().catch(() => {});
  }

  el.btnCloseVideoModal?.addEventListener('click', () => {
    el.detailVideoElement.pause();
    el.modalVideoPlayer.style.display = 'none';
  });

  el.btnDownloadVideo?.addEventListener('click', () => {
    if (!state.activeVideoItem) return;
    const a = document.createElement('a');
    a.href = state.activeVideoItem.url;
    a.download = `${state.activeVideoItem.title}.mp4`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    log(`[Photos] Lưu video "${state.activeVideoItem.title}" vào Cuộn Camera thành công.`, 'success');
  });

  el.btnDeleteVideo?.addEventListener('click', () => {
    if (!state.activeVideoItem) return;
    state.recordings = state.recordings.filter(r => r.id !== state.activeVideoItem.id);
    renderRecordings();
    el.modalVideoPlayer.style.display = 'none';
    log(`[StorageManager] Đã xóa video ${state.activeVideoItem.title}`, 'warn');
  });

  // =========================================================================
  // VIDEO EDITOR MODAL CONTROLLER
  // =========================================================================
  function openEditor(videoItem) {
    const item = videoItem || state.recordings[0];
    if (!item) return;

    state.activeVideoItem = item;
    el.editorVideoElement.src = item.url;
    el.trimStart.max = item.duration;
    el.trimEnd.max = item.duration;
    el.trimStart.value = 0;
    el.trimEnd.value = item.duration;
    updateTrimLabels();

    el.editorWatermarkOverlay.style.display = (state.isVIP && !el.editorWatermarkCheck.checked) ? 'none' : 'block';
    el.modalVideoPlayer.style.display = 'none';
    el.modalEditor.style.display = 'flex';
    el.exportProgress.style.display = 'none';
    el.editorVideoElement.play().catch(() => {});
    log(`[VideoEditor] Mở clip "${item.title}" để chỉnh sửa.`, 'info');
  }

  function updateTrimLabels() {
    const s = parseFloat(el.trimStart.value).toFixed(1);
    const e = parseFloat(el.trimEnd.value).toFixed(1);
    el.trimValuesLabel.textContent = `${s}s - ${e}s`;
  }

  el.trimStart?.addEventListener('input', () => {
    if (parseFloat(el.trimStart.value) >= parseFloat(el.trimEnd.value)) {
      el.trimStart.value = parseFloat(el.trimEnd.value) - 0.5;
    }
    updateTrimLabels();
    el.editorVideoElement.currentTime = parseFloat(el.trimStart.value);
  });

  el.trimEnd?.addEventListener('input', () => {
    if (parseFloat(el.trimEnd.value) <= parseFloat(el.trimStart.value)) {
      el.trimEnd.value = parseFloat(el.trimStart.value) + 0.5;
    }
    updateTrimLabels();
  });

  el.ratioButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      el.ratioButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const ratio = btn.getAttribute('data-ratio');
      if (ratio === 'tiktok') {
        el.editorVideoElement.style.aspectRatio = '9 / 16';
        el.editorVideoElement.style.objectFit = 'cover';
      } else if (ratio === 'youtube') {
        el.editorVideoElement.style.aspectRatio = '16 / 9';
        el.editorVideoElement.style.objectFit = 'contain';
      } else if (ratio === 'square') {
        el.editorVideoElement.style.aspectRatio = '1 / 1';
        el.editorVideoElement.style.objectFit = 'cover';
      } else {
        el.editorVideoElement.style.aspectRatio = 'auto';
        el.editorVideoElement.style.objectFit = 'contain';
      }
      log(`[VideoEditor] Đã crop tỉ lệ: ${ratio}`, 'info');
    });
  });

  el.editorWatermarkCheck?.addEventListener('change', (e) => {
    if (!state.isVIP && !e.target.checked) {
      e.target.checked = true;
      openPaywall();
      return;
    }
    el.editorWatermarkOverlay.style.display = e.target.checked ? 'block' : 'none';
  });

  el.btnExportEditedVideo?.addEventListener('click', () => {
    el.exportProgress.style.display = 'block';
    el.exportBarFill.style.width = '0%';
    let p = 0;
    const interval = setInterval(() => {
      p += 15;
      el.exportBarFill.style.width = `${Math.min(p, 100)}%`;
      if (p >= 100) {
        clearInterval(interval);
        setTimeout(() => {
          el.modalEditor.style.display = 'none';
          const editedRec = {
            id: 'rec-edit-' + Date.now(),
            title: `${state.activeVideoItem.title} (Đã sửa)`,
            duration: Math.max(2, parseFloat(el.trimEnd.value) - parseFloat(el.trimStart.value)),
            durationStr: `00:${String(Math.round(parseFloat(el.trimEnd.value) - parseFloat(el.trimStart.value))).padStart(2, '0')}`,
            sizeStr: '12.8 MB',
            resolution: state.activeVideoItem.resolution,
            fps: state.activeVideoItem.fps,
            date: new Date().toLocaleDateString('vi-VN'),
            url: state.activeVideoItem.url
          };
          state.recordings.unshift(editedRec);
          renderRecordings();
          log('[AVAssetExportSession] Đã xuất video đã chỉnh sửa thành công.', 'success');
          alert('🎉 Xuất video hoàn tất! Video đã lưu vào Thư viện LAICHYM.');
        }, 300);
      }
    }, 150);
  });

  el.btnEditThisVideo?.addEventListener('click', () => openEditor(state.activeVideoItem));
  el.btnCloseEditorModal?.addEventListener('click', () => {
    el.editorVideoElement.pause();
    el.modalEditor.style.display = 'none';
  });
  document.getElementById('cardGoEditor')?.addEventListener('click', () => openEditor(state.recordings[0]));
  el.triggerOpenEditorModal?.addEventListener('click', () => openEditor(state.recordings[0]));

  // Reaction Studio Trigger
  document.getElementById('cardGoReaction')?.addEventListener('click', () => {
    startFaceCam();
    openEditor(state.recordings[0]);
    log('[ReactionStudio] Mở chế độ lồng webcam Reaction.', 'info');
  });

  // =========================================================================
  // STOREKIT 2 PAYWALL CONTROLLER
  // =========================================================================
  function openPaywall() {
    el.modalPaywall.style.display = 'flex';
  }

  el.pwPlanCards.forEach(card => {
    card.addEventListener('click', () => {
      el.pwPlanCards.forEach(c => c.classList.remove('active'));
      card.classList.add('active');
    });
  });

  el.btnSubscribeVIP?.addEventListener('click', () => {
    state.isVIP = true;
    el.modalPaywall.style.display = 'none';
    el.vipPromoBanner.style.display = 'none';
    el.userTierLabel.textContent = 'PRO VIP (Đã kích hoạt)';
    el.heroQualityLabel.textContent = '1080p 60 FPS (PRO)';
    log('[StoreKit 2] Giao dịch Apple In-App Purchase hoàn tất. Mở khóa toàn bộ VIP.', 'success');
    alert('👑 Chúc mừng! Bạn đã kích hoạt thành công gói LAICHYM PRO VIP (3 ngày dùng thử miễn phí).');
  });

  el.btnRestorePurchase?.addEventListener('click', () => {
    state.isVIP = true;
    el.modalPaywall.style.display = 'none';
    log('[StoreKit 2] Khôi phục giao dịch thành công.', 'success');
    alert('Đã khôi phục giao dịch VIP của bạn!');
  });

  el.btnClosePaywall?.addEventListener('click', () => el.modalPaywall.style.display = 'none');
  el.vipPromoBanner?.addEventListener('click', openPaywall);
  el.openPaywallFromHeader?.addEventListener('click', openPaywall);
  el.triggerOpenPaywallModal?.addEventListener('click', openPaywall);

  // Clear Logs
  el.btnClearLog?.addEventListener('click', () => {
    el.consoleLogs.innerHTML = '';
  });

  // Initial Render
  renderRecordings();
  log('[System] Khởi chạy hoàn tất. Sẵn sàng thử nghiệm.', 'success');

})();
