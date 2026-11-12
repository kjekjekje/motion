# 아시안미션(AM) 홍보 모션그래픽

30초, 9:16 (1080×1920), 스위스 그리드 스타일.

- `AsianMission_30s_9x16.mp4`: 완성 영상 (H.264 + AAC, 내레이션 + 배경음악)
- `am_build/index.html`: 애니메이션, 배경음악 합성, 녹화 페이지
- `am_build/server.ps1`: 로컬 서버 (페이지를 띄우고 녹화된 영상을 받아 저장)
- `am_build/tts.ps1`: Edge 뉴럴 음성으로 내레이션 생성 (`vo0~5.mp3`)
- `am_build/vo*.wav`: Windows Heami 음성 내레이션

## 다시 만들기

```
powershell -ExecutionPolicy Bypass -File am_build\server.ps1
```

브라우저에서 http://localhost:8765/ 를 열고 **REC**를 누르면 30초 동안 녹화한 뒤 `AsianMission_30s_9x16.mp4`로 저장됩니다.
