# Bootstrap кодинг-агента на Swift

В репозитории без исходного кода создай минимальный кодинг-агент на Swift. Агент нужен для демонстрации на докладе. Пиши прямой и читаемый код. Не читай другие реализации и не создавай Git-коммит.

## Файлы

Создай:

```text
Package.swift
Package.resolved
Sources/AgentCore/Agent.swift
Sources/AgentCore/Bash.swift
Sources/AgentCLI/main.swift
.env.example
.gitignore
```

Не изменяй существующий `README.md`.

## Swift-пакет

- Используй Swift 6.2 и macOS 13+.
- Назови пакет `PodlodkaCodingAgent`.
- Добавь один исполняемый продукт `agent`.
- Подключи [MacPaw/OpenAI](https://github.com/MacPaw/OpenAI) точной версии `0.5.1`.
- `AgentCore` зависит от `OpenAI`.
- `AgentCLI` зависит от `AgentCore` и `OpenAI`.

## Agent

- Создай один `public final class Agent`.
- Передай в него конкретный клиент `OpenAI`, строку `model` и рабочую директорию как `String`.
- Храни одну историю сообщений SDK. Первым сообщением должен быть системный промпт с рабочей директорией и инструкцией использовать Bash.
- Реализуй в `Agent.run` цикл `пользователь → модель → Bash → результат инструмента → модель`.
- Вызывай enum cases SDK напрямую как `.user(.init(...))`, `.assistant(.init(...))` и `.tool(.init(...))`.
- Не добавляй extensions и helper functions для создания сообщений.
- Не используй общий failable initializer `.init(role: ...)` и force unwrap.
- В сообщение `.assistant` передавай `content`, `reasoningContent: message.reasoning` и `toolCalls`.
- В сообщение `.tool` передавай исходный `tool_call_id`.
- Печатай непустой текст ответа модели.
- Если ответ не содержит вызовов инструментов, заверши текущий `run`.

- Инструмент, доступный модели, называется `bash`.
- Его JSON Schema содержит обязательную строку `command` и `.additionalProperties(.boolean(false))`.
- Декодируй аргументы в закрытую структуру `Decodable`.
- Если модель вызвала другой инструмент, используй `precondition`.
- Перед выполнением команды напечатай её.
- После выполнения вызови `print(output)`.

## Bash

В `Bash.swift` создай один `struct Bash: Sendable`. Храни рабочую директорию как `URL`. Метод `run(_:) async throws -> String` запускает `/bin/bash -c` через `Foundation.Process`.

После `process.run()` используй такой порядок:

```swift
async let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
async let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
let (capturedStdout, capturedStderr) = await (stdoutData, stderrData)
process.waitUntilExit()
```

Объедини непустые stdout, stderr и строку `Exit code: <status>` через перевод строки. Удали `PODLODKA_OPENAI_API_KEY` из окружения дочернего процесса.

## CLI

- Используй `@main enum`.
- Прочитай обязательные `PODLODKA_OPENAI_API_KEY` и `PODLODKA_OPENAI_MODEL`.
- Если нет хотя бы одной из этих переменных, заверши программу без ошибки и без сетевого запроса.
- Используй `PODLODKA_OPENAI_BASE_URL` со значением по умолчанию `https://api.openai.com/v1`.
- Передай в `OpenAI.Configuration` значения `scheme`, `host`, `basePath: baseURL.path` и `parsingOptions: .relaxed`.
- Используй порт `80` для HTTP и `443` для HTTPS, если URL не содержит порт.
- Создай один экземпляр `Agent`.
- В REPL пропускай пустую строку через `continue`. Завершай REPL по `exit` или EOF.
- Оберни каждый вызов агента в `do/catch`. Ошибка API должна печататься и не должна завершать REPL.
- Не печатай возвращённую строку повторно в CLI.

`.env.example` содержит три `export`. Используй значения-заглушки `your-api-key` и `your-tool-capable-model`. `.gitignore` содержит `.build/`, `.swiftpm/`, `.env` и `.DS_Store`.

## Ограничения

- Код будут читать на слайдах. Используй отступ в два пробела и многострочное форматирование.
- Не используй точки с запятой, однострочные блоки, длинные инициализаторы и JSON-схемы в одной строке.
- Не добавляй `AgentConfig`, протоколы, реестр, ограничение числа итераций, собственные модели API и результатов, тесты и механизмы следующих стадий.

## Проверка

Выполни `swift package resolve` и `swift build`. Запусти программу без обязательных env и проверь, что она завершается до сетевого запроса. Не используй настоящий API или ключ. Не оставляй тестовые файлы в проекте.
