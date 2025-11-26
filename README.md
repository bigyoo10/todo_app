# Todo App ✅

Flutter로 만든 개인 포트폴리오용 TODO 앱입니다.  
할 일을 카테고리와 우선순위로 관리하고, 알림과 통계 화면까지 제공하는 **실사용 가능한 일정 관리 앱**을 목표로 개발했습니다.

---

## 📦 Download

Android 기기에서 앱을 바로 설치해볼 수 있습니다.

- **APK 다운로드**: [todo_app_v1.0.0.apk](https://github.com/bigyoo10/todo_app/releases/download/v1.0.0/app-release.apk)


---

## ✨ 주요 기능

- **할 일 추가 / 수정 / 삭제**
  - Title / Description 입력
  - 카테고리: 업무 / 공부 / 개인 / 기타
  - 우선순위: Low / Medium / High
- **알림 기능**
  - 날짜, 시간 선택 후 로컬 알림 예약
  - 알림 도착 후 클릭 시 앱으로 이동
- **통계(Statistics) 화면**
  - Today / Week / Month 탭 전환
  - 완료율(도넛 차트)
  - Total Tasks, High Priority 개수 카드로 요약
- **설정(Settings)**
  - 라이트 / 다크 / 시스템 테마 설정
  - 앱 내 알림 허용 on/off
  - 시스템 알림 권한 상태 및 Android 13+ Exact alarm 안내
- **UI/UX**
  - 그라디언트 배경의 스플래시 화면
  - 카테고리 칩, 우선순위 세그먼트 등 직관적인 입력 UI

---

## 📸 Screenshots

> 실제 기기에서 실행한 화면입니다.  


### 1. 스플래시 & 새 할 일 추가

| 스플래시 화면 | Add New Task |
|--------------|-------------|
| ![Splash](screenshots/splash.jpg) | ![Add Task](screenshots/add_task.png) |

### 2. 알림 흐름

| 시간 선택 다이얼로그 | 알림 도착(알림 센터) |
|----------------------|----------------------|----------------------|
| ![Time Picker](screenshots/time_picker.png) | ![Notification](screenshots/notification.png) | 

### 3. 설정 & 통계 화면

| 설정 화면 | 통계 화면 |
|----------|----------|
| ![Settings](screenshots/settings.png) | ![Statistics](screenshots/statistics.png) |

---

## 🛠 기술 스택

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Riverpod
- **Local DB**: Hive, hive_flutter
- **Notification**: flutter_local_notifications
- **기타**: shared_preferences (설정값 저장 등)

---

## 📂 폴더 구조 (요약)

```text
lib/
  main.dart             # 앱 엔트리, ProviderScope 설정
  models/               # Todo 모델, Hive 어댑터
  services/             # Local DB, Notification 등 서비스 레이어
  providers/            # Riverpod 상태 (Todo 리스트, 필터, 테마 등)
  pages/                # 홈, 통계, 설정, Add/Edit Task 등 화면
  widgets/              # 재사용 위젯 (Todo 카드, 다이얼로그, 통계 카드 등)
  theme/                # 다크/라이트 테마 설정
  utils/                # 공통 상수 및 유틸 함수

apk/
  todo_app_v1.0.0.apk   # Android 설치 파일

screenshots/
  splash.png
  add_task.png
  time_picker.png
  notification.png
  notification_open.png
  settings.png
  statistics.png
