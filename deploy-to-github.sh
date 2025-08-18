#!/bin/bash

# GitHub 저장소 URL을 여기에 입력하세요
GITHUB_REPO_URL="https://github.com/YOUR_USERNAME/sbg-technologies-website.git"

echo "GitHub 저장소에 푸시 중..."

# 원격 저장소 추가
git remote add origin $GITHUB_REPO_URL

# main 브랜치로 설정
git branch -M main

# GitHub에 푸시
git push -u origin main

echo "✅ GitHub 푸시 완료!"
echo "이제 Netlify에서 이 저장소를 연결할 수 있습니다."