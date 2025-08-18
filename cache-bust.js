// 캐시 버스팅을 위한 버전 관리
const APP_VERSION = 'v2.0.0-' + new Date().getTime();

// 페이지 로드 시 버전 확인
if ('serviceWorker' in navigator) {
    // 기존 서비스 워커 제거
    navigator.serviceWorker.getRegistrations().then(function(registrations) {
        for(let registration of registrations) {
            registration.unregister();
        }
    });
}

// localStorage 클리어
try {
    localStorage.clear();
    sessionStorage.clear();
} catch(e) {
    console.log('Storage clear failed:', e);
}

// 강제 리로드
if (window.location.href.includes('?v=')) {
    // 이미 버전 파라미터가 있으면 스킵
} else {
    // 버전 파라미터 추가하여 리로드
    window.location.href = window.location.href + '?v=' + APP_VERSION;
}