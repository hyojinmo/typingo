#!/bin/bash

set -e

echo "🔧 Post-clone: Secret.xcconfig 파일 생성 시작"

# 프로젝트 루트로 이동
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)
echo "📍 Project root: $PROJECT_ROOT"

# Supporting Files 디렉토리 찾기
SUPPORTING_FILES_DIR=""
POSSIBLE_PATHS=(
    "$PROJECT_ROOT/typingo/Supporting Files"
    "$PROJECT_ROOT/typingo/typingo/Supporting Files"
    "$PROJECT_ROOT/Supporting Files"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        SUPPORTING_FILES_DIR="$path"
        echo "✅ Supporting Files 디렉토리 발견: $path"
        break
    fi
done

if [ -z "$SUPPORTING_FILES_DIR" ]; then
    echo "❌ Supporting Files 디렉토리를 찾을 수 없습니다"
    exit 1
fi

# Supporting Files 디렉토리로 이동
cd "$SUPPORTING_FILES_DIR"

# Environment Variable 확인
if [ -z "$OPEN_AI_SECRET" ]; then
    echo "❌ OPEN_AI_SECRET 환경 변수가 설정되지 않았습니다"
    exit 1
fi

# Secret.xcconfig 파일 생성
cat > Secret.xcconfig << EOF
// Auto-generated Secret configuration
// Generated at: $(date)

OPEN_AI_SECRET = ${OPEN_AI_SECRET}
EOF

echo "✅ Secret.xcconfig 파일이 생성되었습니다"

# 파일 존재 확인
if [ -f "Secret.xcconfig" ]; then
    echo "📄 파일 내용 확인:"
    sed 's/= .*/= ***MASKED***/g' Secret.xcconfig
else
    echo "❌ Secret.xcconfig 파일 생성 실패"
    exit 1
fi

echo "🎉 Post-clone script 완료"
