# Прочитать восемь файлов

Прочитай целиком следующие файлы по порядку. Для каждого файла сделай отдельный вызов `read_file` в основном агенте:

1. `experiments/context/micro-compact/files/01-cache.log`
2. `experiments/context/micro-compact/files/02-network.log`
3. `experiments/context/micro-compact/files/03-storage.log`
4. `experiments/context/micro-compact/files/04-images.log`
5. `experiments/context/micro-compact/files/05-search.log`
6. `experiments/context/micro-compact/files/06-sync.log`
7. `experiments/context/micro-compact/files/07-startup.log`
8. `experiments/context/micro-compact/files/08-telemetry.log`

Между этими чтениями не вызывай другие инструменты и не делегируй чтение субагенту. Не меняй файлы. После последнего чтения одним предложением скажи, о чём эти логи; содержимое не перепечатывай.
