# SBG Technologies 웹사이트

AI 기반 자동차 사고 처리 솔루션을 제공하는 SBG Technologies의 공식 웹사이트입니다.

## 🚀 Netlify 배포 방법

### 방법 1: Git 저장소 연결 (권장)

1. 이 프로젝트를 GitHub에 푸시합니다:
```bash
git init
git add .
git commit -m "Initial commit - SBG Technologies website with Silicon template"
git branch -M main
git remote add origin [your-github-repo-url]
git push -u origin main
```

2. Netlify에서 "Import from Git" 클릭
3. GitHub 연결 및 저장소 선택
4. 자동으로 배포 설정이 적용됩니다 (netlify.toml 파일 사용)

### 방법 2: 수동 배포 (드래그 앤 드롭)

1. 이 폴더 전체를 압축하거나
2. Netlify 대시보드에서 폴더를 직접 드래그 앤 드롭

## 📁 프로젝트 구조

```
홈페이지/
├── Silicon/                 # Silicon 템플릿 리소스
│   ├── assets/              # CSS, JS, 이미지 등
│   └── ...                  # 기타 템플릿 파일
├── index-silicon.html       # 메인 홈페이지
├── login-silicon.html       # 로그인 페이지
├── signup-silicon.html      # 회원가입 페이지
├── netlify.toml            # Netlify 설정 파일
└── README.md               # 이 파일
```

## 🔧 Netlify 설정

`netlify.toml` 파일에 다음 설정이 포함되어 있습니다:

- **리디렉션**: 
  - `/` → `/index-silicon.html`
  - `/login` → `/login-silicon.html`
  - `/signup` → `/signup-silicon.html`

- **보안 헤더**: XSS 보호, 클릭재킹 방지 등
- **캐싱 설정**: 정적 자산 최적화
- **404 페이지**: Silicon 템플릿의 404 페이지 사용

## 🌐 배포 후 확인사항

1. **도메인 설정**: Netlify 대시보드에서 커스텀 도메인 설정
2. **HTTPS 활성화**: 자동으로 SSL 인증서 적용
3. **폼 처리**: 문의 폼이 있는 경우 Netlify Forms 활성화

## 📝 환경 변수 (필요시)

API 키나 비밀 정보가 필요한 경우:
1. Netlify 대시보드 → Site settings → Environment variables
2. 필요한 환경 변수 추가

## 🔄 업데이트 방법

### Git 연결된 경우:
```bash
git add .
git commit -m "Update website"
git push
```
Netlify가 자동으로 재배포합니다.

### 수동 배포의 경우:
Netlify 대시보드에서 새 버전을 드래그 앤 드롭

## 📞 지원

문제가 있으시면 연락주세요:
- 이메일: support@sbg-technologies.com
- 웹사이트: https://www.sbg-technologies.com

---

© 2025 SBG Technologies Inc. All rights reserved.