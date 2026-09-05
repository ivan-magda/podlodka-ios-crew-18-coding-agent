# Промпты для воспроизведения

Эти промпты помогают воссоздать каждый этап учебного кодинг-агента на Swift. Для каждого промпта подготовьте отдельную рабочую директорию с содержимым указанного входного тега.

| Промпт                   | Входной тег               | Результат                 |
| ------------------------ | ------------------------- | ------------------------- |
| `00-bootstrap.md`        | `stage-start`             | `stage-bootstrap`         |
| `01-tools-guardrails.md` | `stage-bootstrap`         | `stage-m1-tools`          |
| `02-planning-state.md`   | `stage-m1-tools`          | `stage-m2-planning`       |
| `03-subagents.md`        | `stage-m2-planning`       | `stage-m3-subagents`      |
| `04a-micro-compact.md`   | `stage-m3-subagents`      | `stage-m4a-micro-compact` |
| `04b-auto-compact.md`    | `stage-m4a-micro-compact` | `stage-m4b-auto-compact`  |
| `05-skills.md`           | `stage-m4b-auto-compact`  | `stage-m5-skills`         |
| `06-verification.md`     | `stage-m5-skills`         | `stage-m6-verification`   |

Сначала скопируйте текст выбранного промпта. Затем экспортируйте содержимое входного тега в новую директорию без каталога `prompts/`. Передайте промпт кодинг-агенту в новой сессии, не показывая остальные промпты и готовую реализацию следующего этапа.

Результат не обязан побайтово совпадать с готовой реализацией. Проверьте, что нужный механизм работает, ограничения этапа соблюдены, а проект собирается.
