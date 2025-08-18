# 손보공 홈페이지 배포 가이드

## 배포 방법

### 1. GitHub Pages를 통한 배포 (무료)

1. GitHub 계정으로 로그인
2. 새 repository 생성 (예: sonbogong-homepage)
3. 파일 업로드:
   - sonbogong_homepage.html을 index.html로 이름 변경
   - GitHub에 업로드
4. Settings > Pages에서 GitHub Pages 활성화
5. 배포 URL: https://[username].github.io/sonbogong-homepage

### 2. Netlify를 통한 배포 (무료)

1. https://www.netlify.com 접속
2. GitHub/GitLab/Bitbucket 계정으로 로그인
3. "Drop your site folder here" 영역에 홈페이지 폴더 드래그
4. 자동으로 배포 완료
5. 커스텀 도메인 설정 가능

### 3. 현재 서버 (api.sbg-technologies.com)에 직접 배포

서버 관리자에게 다음 파일을 전달:
- sonbogong_homepage.html (또는 index.html로 이름 변경)

### 4. Vercel을 통한 배포 (무료)

1. https://vercel.com 접속
2. GitHub 계정으로 로그인
3. Import Project > 파일 업로드
4. 자동 배포 완료

## 배포 전 체크리스트

- [ ] API URL이 올바른지 확인 (https://api.sbg-technologies.com)
- [ ] 모든 링크가 정상 작동하는지 확인
- [ ] 반응형 디자인 테스트
- [ ] 폼 제출 기능 테스트

## 추가 설정

### CORS 설정 (서버 관리자용)
서버에서 다음 헤더 추가 필요:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

### SSL 인증서
HTTPS 프로토콜 사용을 위해 SSL 인증서 필요 (Let's Encrypt 무료 인증서 권장)