# Промпты для воспроизведения

Эти промпты последовательно воспроизводят стадии демонстрационного Swift-кодинг-агента. Применяйте каждый промпт к указанному входному тегу в отдельной рабочей директории.

| Промпт | Входной тег | Результат |
|---|---|---|
| `00-bootstrap.md` | `stage-start` | `stage-bootstrap` |
| `01-tools-guardrails.md` | `stage-bootstrap` | `stage-m1-tools` |
| `02-planning-state.md` | `stage-m1-tools` | `stage-m2-planning` |
| `03-subagents.md` | `stage-m2-planning` | `stage-m3-subagents` |
| `04a-micro-compact.md` | `stage-m3-subagents` | `stage-m4a-micro-compact` |
| `04b-auto-compact.md` | `stage-m4a-micro-compact` | `stage-m4b-auto-compact` |
| `05-skills.md` | `stage-m4b-auto-compact` | `stage-m5-skills` |
| `06-verification.md` | `stage-m5-skills` | `stage-m6-verification` |

Для чистого эксперимента сначала скопируйте текст выбранного промпта. Затем экспортируйте входной тег в новую директорию без каталога `prompts/`. Передайте текст свежему кодинг-агенту. Не показывайте агенту остальные промпты и целевую реализацию.

Побайтовое совпадение не требуется. Проверьте механизм стадии, её ограничения и успешную сборку.
