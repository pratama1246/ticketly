# AI_RULES.md

## Context
- Framework: CodeIgniter
- Project: Ticketly
- API digunakan untuk Flutter/mobile
- Struktur folder terbaru adalah referensi utama
- Existing web project adalah acuan utama consistency

---

## Main Goal
Tugas utama adalah MERAPIKAN dan MENYAMAKAN layer API dengan existing project.

Fokus hanya pada:
- API Controller
- JWT/Auth
- Filter/Middleware
- Helper
- Validation
- API Route
- Response API
- Pagination/Search/Filter API

Bukan membuat backend baru dari nol.

---

## Priority
Prioritaskan:
1. Struktur project terbaru
2. Existing naming convention
3. Existing coding style
4. Existing response format

---

## Rules
- Ikuti pola existing project
- Jangan overengineering
- Jangan membuat architecture baru
- Jangan rewrite total
- Jangan rename tanpa alasan jelas
- Jangan membuat abstraction tambahan yang tidak diperlukan
- Pertahankan bagian API yang sudah konsisten

---

## Folder Rules
- Ikuti struktur folder terbaru
- Jangan memindahkan file tanpa alasan kuat
- File baru harus mengikuti pola folder existing

---

## API Rules
- Gunakan JWT flow existing project
- Gunakan response format yang konsisten
- Validation harus mengikuti style existing
- Route API harus seragam
- Error handling harus konsisten

---

## Do Not Do
- Jangan redesign project
- Jangan mengubah web controller yang sudah stabil
- Jangan membuat clean architecture baru
- Jangan menambahkan service/repository/usecase jika project tidak konsisten menggunakannya
- Jangan mengubah database besar-besaran

---

## Workflow
1. Baca existing project terlebih dahulu
2. Audit API yang sudah dibuat
3. Bandingkan dengan existing project
4. Perbaiki inkonsistensi seperlunya
5. Lakukan perubahan seminimal mungkin
