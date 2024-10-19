#!/bin/bash

LOG_DIR="/LOG"
BACKUP_DIR="/BACKUP"
BACKUP_SCRIPT="./backup.sh"  # Путь к первому скрипту

# 1. Функция для подготовки тестового окружения
setup_test_env() {
    echo "Подготовка тестового окружения..."

    # Убедимся, что папки существуют
    if [ ! -d "$LOG_DIR" ]; then
        echo "Ошибка: Папка $LOG_DIR не существует!"
        exit 1
    fi

    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Ошибка: Папка $BACKUP_DIR не существует!"
        exit 1
    fi

    # Генерируем тестовые файлы размером 100 MB в /LOG, если их недостаточно
    EXISTING_FILES=$(ls -1 "$LOG_DIR" | wc -l)
    FILES_TO_CREATE=$((5 - EXISTING_FILES))
    if [ "$FILES_TO_CREATE" -gt 0 ]; then
        echo "Создание $FILES_TO_CREATE тестовых файлов..."
        for i in $(seq 1 "$FILES_TO_CREATE"); do
            sudo dd if=/dev/zero of="$LOG_DIR/log_file_$i.log" bs=10M count=10  # Генерация файлов по 100MB
            sleep 1  # Задержка для уникальности времени создания файлов
        done
    else
        echo "Достаточное количество файлов уже существует в $LOG_DIR"
    fi
}

# 2. Функция для выполнения тестов
run_tests() {
    echo "Запуск тестов..."
    OLDEST_FILES=$(ls -1t "$LOG_DIR" | tail -n 2)  # Находим 2 самых старых файла до архивации (для 5 теста)
    
    # Тест 1: Проверка порога использования 40%
    echo "Тест 1: Проверка архивирования при использовании диска выше 40%"
    sudo bash "$BACKUP_SCRIPT" -p 40 -n 3
    if [ "$(ls -1 $LOG_DIR | wc -l)" -lt 3 ]; then
        echo "Тест 1 пройден!"
    else
        echo "Тест 1 провален!"
    fi

    # Тест 2: Проверка при отсутствии файлов для архивирования
    echo "Тест 2: Нет файлов для архивирования"
    sudo bash "$BACKUP_SCRIPT" -p 90 -n 1
    if [ "$(ls -1 $LOG_DIR | wc -l)" -eq 2 ]; then
        echo "Тест 2 пройден!"
    else
        echo "Тест 2 провален!"
    fi

    # Тест 3: Проверка создания архива
    echo "Тест 3: Проверка создания архива"
    if [ "$(ls -1 $BACKUP_DIR | wc -l)" -gt 0 ]; then
        echo "Тест 3 пройден!"
    else
        echo "Тест 3 провален!"
    fi

    # Тест 4: Проверка корректности удаления файлов
    echo "Тест 4: Проверка удаления файлов из /LOG после архивации"
    if [ "$(ls -1 $LOG_DIR | wc -l)" -lt 3 ]; then
        echo "Тест 4 пройден!"
    else
        echo "Тест 4 провален!"
    fi

    # Тест 5: Проверка удаления самых старых файлов
    echo "Тест 5: Проверка удаления самых старых файлов"
    REMAINING_FILES=$(ls -1 "$LOG_DIR")  # Проверяем оставшиеся файлы после архивации
    if ! echo "$OLDEST_FILES" | grep -q -F "$REMAINING_FILES"; then
        echo "Тест 5 пройден! Самые старые файлы были удалены."
    else
        echo "Тест 5 провален! Не те файлы были удалены."
    fi

    # Тест 6: Проверка поведения при количестве файлов меньше, чем указано для архивирования
    echo "Тест 6: Проверка поведения при недостаточном количестве файлов для архивирования"
    sudo bash "$BACKUP_SCRIPT" -p 10 # Запрос на архивирование всех файлов
    if [ "$(ls -1 $LOG_DIR | wc -l)" -eq 0 ]; then
        echo "Тест 6 пройден! Все доступные файлы были заархивированы."
    else
        echo "Тест 6 провален!"
    fi
}

# 3. Запуск тестов
setup_test_env
run_tests

