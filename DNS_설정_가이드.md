# SBG Technologies 도메인 DNS 설정 가이드

## 현재 상황
- 홈페이지: Netlify에 배포됨
- API 서버: api.sbg-technologies.com (이미 작동 중)
- 필요한 작업: www.sbg-technologies.com을 Netlify로 연결

## DNS 설정 방법

### 1. 도메인 등록업체 관리 패널 접속
도메인을 구매한 업체(예: GoDaddy, Namecheap, 가비아 등)의 관리 패널에 로그인

### 2. DNS 레코드 추가

#### A 레코드 (루트 도메인용)
```
Type: A
Name: @ (또는 공백)
Value: 75.2.60.5
TTL: 3600
```

#### CNAME 레코드 (www 서브도메인용)
```
Type: CNAME
Name: www
Value: glittering-fudge-568c15.netlify.app
TTL: 3600
```

### 3. 기존 API 서버 유지
api 서브도메인은 현재 설정 그대로 유지:
```
Type: A 또는 CNAME
Name: api
Value: (현재 Cloudflare 설정 유지)
```

## 설정 후 확인
1. DNS 전파 시간: 최대 24-48시간 (보통 1-2시간)
2. Netlify에서 자동으로 SSL 인증서 발급
3. https://www.sbg-technologies.com 접속 가능

## 최종 도메인 구조
- www.sbg-technologies.com → 홈페이지 (Netlify)
- api.sbg-technologies.com → API 서버 (Cloudflare)
- sbg-technologies.com → www로 리다이렉트