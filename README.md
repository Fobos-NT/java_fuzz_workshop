# Fuzzing pdfbox

## Подготовка окружения

Собираем docker образ:

```bash
git clone https://github.com/lenix123/java_fuzz_workshop.git && cd java_fuzz_workshop
docker build --tag=pdfbox_workshop_img .
```

Запускаем контейнер:

```bash
docker run -it -v "$(pwd)/artifacts:/home/fuzz/artifacts:ro" -v "$SYDR_PATH:/sydr/" --network=host -v /var/hasplm:/var/hasplm --cap-add=SYS_PTRACE --security-opt seccomp=unconfined --name=pdfbox_fuzz pdfbox_workshop_img
```

## Подготовка корпуса

Подготавливаем входной корпус:

```bash
mkdir -p pdfbox/src/test/resources/org/apache/pdfbox/pdfparser/PDFStreamParserTestInputs
cp /home/fuzz/artifacts/corpus/* pdfbox/src/test/resources/org/apache/pdfbox/pdfparser/PDFStreamParserTestInputs
```

Собираем тесты и запускаем фаззинг FuzzTestPDFParser:

```bash
cd /home/fuzz/pdfbox
mvn clean install -DskipTests
cd /home/fuzz/pdfbox/pdfbox
JAZZER_FUZZ=1 mvn test -Dtest=PDFStreamParserTest#FuzzTestPDFParser
```

Наработанный корпус хранится в `/home/fuzz/pdfbox/pdfbox/.cifuzz-corpus/`

## Фаззинг java кода с помощью jazzer

Cобираем обёртку для pdfbox:

```bash
cd /home/fuzz/pdfbox
mkdir fuzz && cd fuzz
cp -r /home/fuzz/artifacts/* .
javac -cp ../pdfbox/target/classes/ ./PDFStreamParserFuzzer.java
```

Запускаем фаззинг PDF парсера:

```bash
jazzer --cp=/home/fuzz/pdfbox/fuzz:/home/fuzz/pdfbox/pdfbox/target/classes/:/home/fuzz/pdfbox/io/target/classes/:/home/fuzz/log4j/commons-logging-1.2/commons-logging-1.2.jar --target_class=PDFStreamParserFuzzer -dict=pdf.dict -close_fd_mask=3 -- corpus
```

## Сбор покрытия 

Прогоняем наработанный корпус:

```bash
cd /home/fuzz/pdfbox/fuzz
jazzer --cp=/home/fuzz/pdfbox/fuzz:/home/fuzz/pdfbox/pdfbox/target/classes/:/home/fuzz/pdfbox/io/target/classes/:/home/fuzz/log4j/commons-logging-1.2/commons-logging-1.2.jar --target_class=PDFStreamParserFuzzer -close_fd_mask=3 --coverage_dump=coverage.exec -runs=1 -- corpus
```

Генерируем html отчёт с помощью jacococli:

```bash
java -jar /home/fuzz/jacoco/lib/jacococli.jar report coverage.exec --classfiles /home/fuzz/pdfbox/pdfbox/target/pdfbox-3.0.5.jar --html report --sourcefiles /home/fuzz/pdfbox/pdfbox/src/main/java/
```

Копируем папку с html отчётом на хост:

```bash
docker cp pdfbox_fuzz:/home/fuzz/pdfbox/fuzz/report .
```

## Запускаем jazzer с помощью sydr-fuzz

1. Чтобы запустить фаззинг при помощи sydr-fuzz:

```bash
cd /home/fuzz/pdfbox/fuzz
/sydr/sydr-fuzz -c pdfStreamParser_sydr.toml run
```

Все артефакты фаззинга находятся в выходной директории sydr-fuzz: `/tmp/PDFStreamParserFuzzer_out/`

2. Чтобы минимизировать наработанный корпус:

```bash
/sydr/sydr-fuzz -c pdfStreamParser_sydr.toml cmin
```

Минимизированный корпус находится в директории `/tmp/PDFStreamParserFuzzer_out/corpus`. Полный корпус до минимизации находится в директории `/tmp/PDFStreamParserFuzzer_out/corpus-old`

3. Для сбора покрытия:

```bash
/sydr/sydr-fuzz -c pdfStreamParser_sydr.toml cov-html
```

HTML-отчёт о наработанном покрытии находится в директории `/tmp/PDFStreamParserFuzzer_out/coverage`

4. Анализ найденных падений при помощи casr:

```bash
/sydr/sydr-fuzz -c pdfStreamParser_sydr.toml casr
```

Результаты запуска находятся в директории `/tmp/PDFStreamParserFuzzer_out/casr`
