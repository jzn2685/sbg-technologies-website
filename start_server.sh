#!/bin/bash

# 간단한 Python HTTP 서버로 홈페이지 실행
echo "손보공 홈페이지 로컬 서버를 시작합니다..."
echo "브라우저에서 http://localhost:8000/sonbogong_homepage.html 로 접속하세요"
echo "종료하려면 Ctrl+C를 누르세요"

cd "$(dirname "$0")"
python3 -m http.server 8000