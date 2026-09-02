---
name: example
description: Объясняет формат и загрузку skills в этом агенте
---

Skills хранят специализированные инструкции в `skills/<name>/SKILL.md`.

Агент видит в system prompt только имя и описание skill. Полный текст этой
инструкции появляется в контексте после вызова `load_skill`.
