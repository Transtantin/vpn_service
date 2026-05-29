import sqlite3
import sys
import uuid

def main():
    print("=== Утилита добавления нового сервера/конфига в базу данных ===")
    
    # Подключаемся к локальной БД SQLite
    db_path = "vpn_database.db"
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Сначала покажем существующие серверы (ID)
    cursor.execute("SELECT id, name, ip FROM servers")
    servers = cursor.fetchall()
    
    if not servers:
        print("В базе нет серверов. Создадим новый!")
        server_id = str(uuid.uuid4())[:8]
        name = input("Введите имя сервера (например, Premium EU): ")
        location = input("Введите локацию (например, Germany, Berlin): ")
        flagUrl = input("Введите ссылку на флаг (например, https://flagcdn.com/w80/de.png): ")
        ip = input("Введите IP-адрес сервера: ")
        
        cursor.execute(
            "INSERT INTO servers (id, name, location, flagUrl, ip, ping) VALUES (?, ?, ?, ?, ?, ?)",
            (server_id, name, location, flagUrl, ip, 0)
        )
        print(f"Сервер {name} (ID: {server_id}) успешно добавлен!")
    else:
        print("\nСуществующие серверы:")
        for s in servers:
            print(f"ID: {s[0]} | Имя: {s[1]} | IP: {s[2]}")
        
        choice = input("\nХотите добавить конфиг к существующему серверу (1) или создать новый сервер (2)? [1/2]: ")
        
        if choice == '1':
            server_id = input("Введите ID существующего сервера из списка выше: ")
        else:
            server_id = str(uuid.uuid4())[:8]
            name = input("Введите имя сервера (например, Premium EU): ")
            location = input("Введите локацию (например, Germany, Berlin): ")
            flagUrl = input("Введите ссылку на флаг (например, https://flagcdn.com/w80/de.png): ")
            ip = input("Введите IP-адрес сервера: ")
            
            cursor.execute(
                "INSERT INTO servers (id, name, location, flagUrl, ip, ping) VALUES (?, ?, ?, ?, ?, ?)",
                (server_id, name, location, flagUrl, ip, 0)
            )
            print(f"Сервер {name} (ID: {server_id}) успешно добавлен!")

    print("\n--- Добавление конфигурации (ссылки vless://, ss://, vmess://) ---")
    config_string = input("Вставьте вашу ссылку: ").strip()
    
    # Определяем протокол по началу ссылки
    protocol = config_string.split("://")[0] if "://" in config_string else "unknown"

    if protocol not in ["vless", "ss", "vmess", "trojan"]:
        print(f"Предупреждение: Неизвестный протокол '{protocol}'. Убедитесь, что ссылка правильная.")

    # Добавляем в таблицу configs
    cursor.execute(
        "INSERT INTO configs (server_id, protocol, config_string, priority) VALUES (?, ?, ?, ?)",
        (server_id, protocol, config_string, 100)
    )
    
    conn.commit()
    conn.close()
    
    print("\n✅ Успешно! Конфигурация добавлена в vpn_database.db.")
    print("Теперь просто перезапустите бэкенд (FastAPI), и мобильное приложение автоматически увидит новый сервер при запуске!")

if __name__ == "__main__":
    main()
