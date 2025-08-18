# Cloudflare DNS 설정 가이드

## Cloudflare 대시보드에서 설정하기

### 1. Cloudflare 로그인
- https://dash.cloudflare.com 접속
- sbg-technologies.com 도메인 선택

### 2. DNS 설정
좌측 메뉴에서 "DNS" 클릭

### 3. 필요한 DNS 레코드 추가/수정

#### 홈페이지용 설정 (Netlify)

**옵션 1: 프록시 비활성화 (권장)**
```
Type: CNAME
Name: www
Content: glittering-fudge-568c15.netlify.app
Proxy status: DNS only (회색 구름)
TTL: Auto
```

```
Type: CNAME  
Name: @ (또는 sbg-technologies.com)
Content: glittering-fudge-568c15.netlify.app
Proxy status: DNS only (회색 구름)
TTL: Auto
```

**중요**: Proxy status를 "DNS only"로 설정해야 Netlify가 SSL 인증서를 발급할 수 있습니다.

#### API 서버 설정 (현재 유지)
```
Type: A 또는 CNAME
Name: api
Content: (현재 설정 유지)
Proxy status: Proxied (주황색 구름) - 현재 설정 유지
```

### 4. 설정 시 주의사항

#### Proxy 상태 설명:
- 🟠 **Proxied** (주황색 구름): Cloudflare를 통해 트래픽이 전달됨
- ⚫ **DNS only** (회색 구름): 직접 연결 (Netlify 필수)

#### 왜 DNS only가 필요한가?
- Netlify는 자체 SSL 인증서를 발급합니다
- Cloudflare 프록시를 사용하면 SSL 충돌이 발생합니다
- DNS only로 설정해야 Netlify가 도메인을 인증할 수 있습니다

### 5. 설정 후 확인
1. DNS 변경사항 저장
2. 5-10분 후 Netlify 대시보드에서 확인
3. "Awaiting External DNS"가 사라지고 SSL 인증서가 발급됨

### 6. 최종 도메인 구조
- https://www.sbg-technologies.com → Netlify 홈페이지 (DNS only)
- https://sbg-technologies.com → Netlify 홈페이지 (DNS only)
- https://api.sbg-technologies.com → API 서버 (Proxied 유지)

## 문제 해결

### DNS 검증 실패가 계속되는 경우:
1. Cloudflare에서 해당 레코드의 Proxy를 반드시 끄기 (DNS only)
2. 기존 A 레코드가 있다면 삭제하고 CNAME으로 대체
3. 10-15분 기다린 후 Netlify에서 "Verify DNS configuration" 클릭

### SSL 인증서 오류:
1. Cloudflare SSL/TLS 설정을 "Full" 또는 "Flexible"로 설정
2. Netlify에서 자동 SSL 발급 완료까지 대기 (최대 24시간)