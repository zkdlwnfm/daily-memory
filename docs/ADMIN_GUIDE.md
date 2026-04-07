# Engram Admin Dashboard Guide

## 접속 정보

| 항목 | 값 |
|---|---|
| URL | https://dailymemory.pjhdev.co.kr/admin.html |
| Admin Key | `engram-admin-2026` |
| API Docs (Swagger) | https://dailymemory.pjhdev.co.kr/docs |

## 접속 방법

1. 브라우저에서 https://dailymemory.pjhdev.co.kr/admin.html 접속
2. 우측 상단 Admin Key 입력란에 `engram-admin-2026` 입력
3. **Connect** 클릭

## 대시보드 섹션

### 상단 통계 카드

| 카드 | 설명 |
|---|---|
| Total Users | 전체 등록 사용자 수 |
| Premium Users | 프리미엄 사용자 수 |
| API Calls Today | 오늘 전체 API 호출 수 (성공/에러 분리 표시) |
| Tokens Today | 오늘 사용된 OpenAI 토큰 수 |
| Est. Cost Today | 오늘 추정 OpenAI 비용 (모델별 breakdown 표시) |
| Embeddings Stored | pgvector에 저장된 총 임베딩 수 |

### API Usage (7 days)

최근 7일간 일별 API 호출 수를 바 차트로 표시.

### Usage by Endpoint

| 컬럼 | 설명 |
|---|---|
| Endpoint | API 경로 (ai/analyze, embeddings 등) |
| Model | 사용된 OpenAI 모델 |
| Calls | 호출 횟수 |
| Tokens | 총 사용 토큰 |
| Avg Latency | 평균 응답 시간 (ms) |

### Today's Rate Limit Usage

각 사용자의 오늘 API 사용량 (AI/Image/Embed/Search 별).
- Free tier: AI 30, Image 10, Embed 50, Search 50 /일
- Premium tier: AI 200, Image 100, Embed 500, Search 500 /일

### Users

| 컬럼 | 설명 |
|---|---|
| Email | 사용자 이메일 |
| Tier | Free / Premium |
| Weekly API Calls | 최근 7일 API 호출 수 |
| Last Active | 마지막 활동 시간 |
| Joined | 가입일 |
| Actions | Premium 전환 버튼 |

**Premium 전환**: Users 테이블의 Upgrade/Downgrade 버튼 클릭으로 즉시 전환.

## API 엔드포인트 (직접 호출)

모든 admin 엔드포인트는 `Authorization: Bearer {ADMIN_KEY}` 헤더 필요.

```bash
# 전체 통계
curl -s https://dailymemory.pjhdev.co.kr/api/v1/admin/stats \
  -H "Authorization: Bearer engram-admin-2026"

# 사용량 (기본 7일, ?days=30 으로 변경 가능)
curl -s https://dailymemory.pjhdev.co.kr/api/v1/admin/usage?days=30 \
  -H "Authorization: Bearer engram-admin-2026"

# 사용자 목록
curl -s https://dailymemory.pjhdev.co.kr/api/v1/admin/users \
  -H "Authorization: Bearer engram-admin-2026"

# Rate Limit 현황
curl -s https://dailymemory.pjhdev.co.kr/api/v1/admin/rate-limits \
  -H "Authorization: Bearer engram-admin-2026"

# Premium 전환
curl -X POST https://dailymemory.pjhdev.co.kr/api/v1/admin/users/{firebase_uid}/toggle-premium \
  -H "Authorization: Bearer engram-admin-2026"
```

## 비용 추정 계산 방식

| 모델 | 비율 | 단가 (per 1M tokens) |
|---|---|---|
| text-embedding-3-small | 70% | $0.02 |
| gpt-4o-mini | 25% | $0.30 (avg input+output) |
| gpt-4o (vision) | 5% | $5.00 (avg input+output) |

실제 비용은 OpenAI 대시보드에서 확인: https://platform.openai.com/usage

## 서버 관리

### API 서버 상태 확인
```bash
curl -s https://dailymemory.pjhdev.co.kr/api/v1/health
```

### 서버 재시작
```bash
ssh -p 2222 root@pjhdev.co.kr "ssh root@192.168.50.214 'cd /opt/dailymemory && docker compose restart'"
```

### 로그 확인
```bash
ssh -p 2222 root@pjhdev.co.kr "ssh root@192.168.50.214 'docker logs dailymemory-api --tail 50'"
```

### 재배포
```bash
ssh -p 2222 root@pjhdev.co.kr "ssh root@192.168.50.214 'cd /opt/dailymemory && docker compose down && docker system prune -f && DOCKER_BUILDKIT=0 docker compose up -d --build'"
```

## Airflow DAG 관리

### DAG 목록 확인
```bash
ssh -p 2222 root@pjhdev.co.kr "ssh ubuntu@192.168.50.4 'sudo -u airflow bash -c \"source /opt/airflow/venv/bin/activate && set -a && source /opt/airflow/airflow.env && set +a && airflow dags list | grep dm_\"'"
```

### DAG 일시 중지/재개
```bash
# 중지
airflow dags pause dm_weekly_report

# 재개
airflow dags unpause dm_weekly_report
```

### DAG 수동 실행
```bash
airflow dags trigger dm_weekly_report
```

## 인프라 접속

| 서버 | 접속 방법 |
|---|---|
| Proxmox 호스트 | `ssh -p 2222 root@pjhdev.co.kr` |
| DailyMemory API (LXC 304) | `ssh root@192.168.50.214` (Proxmox 경유) |
| Shared DB (VM 201) | `ssh ubuntu@192.168.50.201` (Proxmox 경유) |
| Airflow (VM 103) | `ssh ubuntu@192.168.50.4` (Proxmox 경유) |
| CI/CD (LXC 303) | `ssh root@192.168.50.213` (Proxmox 경유) |

## Admin Key 변경

1. 서버 `.env` 파일에서 `ADMIN_KEY` 값 변경
2. `docker compose restart` 실행
3. 대시보드에서 새 키로 접속
