# Docker Practice - Inception Project

Bu proje, Docker ve Docker Compose kullanarak modern bir web altyapısı oluşturmayı amaçlayan bir sistem yönetimi çalışmasıdır. Proje, NGINX web sunucusu, MariaDB veritabanı ve WordPress CMS'ini Docker konteynerleri içinde çalıştıran tam işlevsel bir ortam kurar.

## 📋 İçindekiler

- [Proje Hakkında](#-proje-hakkında)
- [Teknolojiler](#-teknolojiler)
- [Proje Yapısı](#-proje-yapısı)
- [Gereksinimler](#-gereksinimler)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Servisler](#-servisler)
- [Makefile Komutları](#-makefile-komutları)
- [Güvenlik](#-güvenlik)
- [Sorun Giderme](#-sorun-giderme)

## 🎯 Proje Hakkında

Bu proje, aşağıdaki modern sistem yönetimi ve DevOps prensiplerini uygular:

- **Konteynerizasyon**: Her servis izole Docker konteynerleri içinde çalışır
- **Mikroservis Mimarisi**: NGINX, MariaDB ve WordPress ayrı servisler olarak yapılandırılmıştır
- **Güvenlik**: TLS/SSL şifreleme, secrets yönetimi ve güvenli ağ yapılandırması
- **Otomatizasyon**: Makefile ile kolay kurulum ve yönetim
- **Veri Kalıcılığı**: Docker volumes ile kalıcı veri depolama

## 🛠 Teknolojiler

### Servisler ve Sürümler

- **NGINX**: Debian Bookworm tabanlı, TLS 1.2/1.3 desteği ile reverse proxy
- **MariaDB**: Alpine Linux 3.21 tabanlı, optimize edilmiş veritabanı sunucusu
- **WordPress**: Debian Bookworm, PHP 8.2-FPM, WP-CLI ile tam otomatik kurulum
- **Docker Compose**: v3.8

### Ana Özellikler

- ✅ TLS/SSL şifreleme (HTTPS)
- ✅ PHP-FPM ile FastCGI
- ✅ Otomatik veritabanı kurulumu
- ✅ Secrets yönetimi
- ✅ Health check mekanizmaları
- ✅ Kalıcı veri depolama (volumes)
- ✅ Ağ izolasyonu

## 📁 Proje Yapısı

```
Docker-Practise/
├── README.md
└── project/
    ├── Makefile
    └── srcs/
        ├── docker-compose.yml
        ├── .env                    # Ortam değişkenleri (oluşturulmalı)
        ├── secrets/                # Güvenlik dosyaları (oluşturulmalı)
        │   ├── db_password.txt
        │   ├── db_root_password.txt
        │   └── wp_admin_password.txt
        └── requirements/
            ├── nginx/
            │   ├── Dockerfile
            │   └── conf/
            │       ├── default.conf
            │       └── ssl/
            │           ├── server.crt
            │           └── server.key
            ├── mariadb/
            │   ├── Dockerfile
            │   └── conf/
            │       └── entrypoint.sh
            └── wordpress/
                ├── Dockerfile
                └── conf/
                    └── entrypoint.sh
```

## 🔧 Gereksinimler

- Docker (20.10 veya üzeri)
- Docker Compose (v2.0 veya üzeri)
- Make
- En az 2GB RAM
- En az 10GB disk alanı

## 🚀 Kurulum

### 1. Ortam Değişkenlerini Ayarlama

`project/srcs/.env` dosyası oluşturun:

```bash
# Veritabanı Ayarları
DB_NAME=wordpress
DB_USER=wpuser

# WordPress Ayarları
WP_URL=https://iozmen.42.fr
WP_TITLE=My WordPress Site
WP_ADMIN_USER=admin
WP_ADMIN_EMAIL=admin@example.com
WP_USER=author
WP_USER_EMAIL=author@example.com
WP_USER_PASS=author123
```

### 2. Secrets Dosyalarını Oluşturma

```bash
# Secrets dizini oluştur
mkdir -p project/secrets

# Şifreleri oluştur (örnekler - güvenli şifreler kullanın!)
echo "your_db_password" > project/secrets/db_password.txt
echo "your_root_password" > project/secrets/db_root_password.txt
echo "your_admin_password" > project/secrets/wp_admin_password.txt

# İzinleri ayarla
chmod 600 project/secrets/*.txt
```

### 3. SSL Sertifikalarını Oluşturma

```bash
# SSL dizini oluştur
mkdir -p project/srcs/requirements/nginx/conf/ssl

# Self-signed sertifika oluştur
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout project/srcs/requirements/nginx/conf/ssl/server.key \
  -out project/srcs/requirements/nginx/conf/ssl/server.crt \
  -subj "/C=TR/ST=Istanbul/L=Istanbul/O=42/OU=Student/CN=iozmen.42.fr"
```

### 4. Veri Dizinlerini Oluşturma

```bash
# Docker volumes için dizinler
mkdir -p /home/$USER/data/wordpress
mkdir -p /home/$USER/data/mariadb
```

**NOT:** `docker-compose.yml` dosyasındaki volume yollarını sisteminize göre güncelleyin:

```yaml
volumes:
  wordpress_data:
    driver_opts:
      device: /home/KULLANICI_ADINIZ/data/wordpress
  mariadb_data:
    driver_opts:
      device: /home/KULLANICI_ADINIZ/data/mariadb
```

### 5. hosts Dosyasını Düzenleme

```bash
# /etc/hosts dosyasına ekleyin
sudo echo "127.0.0.1 iozmen.42.fr" >> /etc/hosts
```

## 💻 Kullanım

### Projeyi Başlatma

```bash
cd project
make
```

Alternatif olarak:

```bash
cd project
docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build
```

### Servislere Erişim

- **WordPress**: https://iozmen.42.fr
- **WordPress Admin**: https://iozmen.42.fr/wp-admin

### Servisleri Durdurma

```bash
make down
```

### Logları İzleme

```bash
# Tüm servislerin logları
docker-compose -f srcs/docker-compose.yml logs -f

# Belirli bir servis
docker-compose -f srcs/docker-compose.yml logs -f nginx
docker-compose -f srcs/docker-compose.yml logs -f wordpress
docker-compose -f srcs/docker-compose.yml logs -f mariadb
```

## 🔌 Servisler

### NGINX (Port: 443)

- **Rol**: Reverse proxy ve web sunucusu
- **Base Image**: Debian Bookworm
- **Özellikler**:
  - TLS 1.2/1.3 desteği
  - SSL sertifikası ile şifreli bağlantı
  - PHP-FPM ile FastCGI iletişimi
  - Static dosyalar için cache
  - WordPress için optimize edilmiş ayarlar

### MariaDB (Port: 3306)

- **Rol**: İlişkisel veritabanı sunucusu
- **Base Image**: Alpine Linux 3.21
- **Özellikler**:
  - UTF8MB4 karakter seti desteği
  - Performans optimizasyonları
  - Otomatik veritabanı kurulumu
  - Health check mekanizması
  - Güvenli kullanıcı yönetimi

**Varsayılan Yapılandırma:**
- Max connections: 100
- InnoDB buffer pool: 256MB
- Query cache: 32MB

### WordPress (Port: 9000 - internal)

- **Rol**: İçerik yönetim sistemi
- **Base Image**: Debian Bookworm
- **PHP Sürümü**: 8.2-FPM
- **Özellikler**:
  - WP-CLI ile tam otomatik kurulum
  - İki kullanıcılı kurulum (admin + author)
  - MariaDB bağlantı kontrolü
  - Tüm gerekli PHP eklentileri

## 📝 Makefile Komutları

| Komut | Açıklama |
|-------|----------|
| `make` veya `make all` | Servisleri build eder ve başlatır |
| `make down` | Servisleri durdurur |
| `make clean` | Servisleri durdurur ve Docker önbelleğini temizler |
| `make fclean` | Tüm Docker kaynaklarını tamamen temizler |
| `make clean-data` | Volume'ları siler ve veri dizinlerini temizler |
| `make re` | Clean + build (yeniden başlatma) |

### Örnek Kullanım

```bash
# İlk kurulum
make

# Servisleri durdurup temizleme
make clean

# Tüm verileri sıfırlayarak yeniden başlatma
make clean-data
sudo rm -rf /home/$USER/data/mariadb/* /home/$USER/data/wordpress/*
make
```

## 🔒 Güvenlik

### Secrets Yönetimi

Proje, hassas bilgileri (şifreler) `secrets` dizininde ayrı dosyalar olarak saklar:

- `db_password.txt`: WordPress veritabanı kullanıcı şifresi
- `db_root_password.txt`: MariaDB root şifresi
- `wp_admin_password.txt`: WordPress admin şifresi

Bu dosyalar read-only olarak konteynerlere mount edilir.

### SSL/TLS

- NGINX yalnızca HTTPS (port 443) üzerinden hizmet verir
- TLS 1.2 ve TLS 1.3 protokolleri kullanılır
- Self-signed sertifika (production için geçerli sertifika kullanın)

### Ağ İzolasyonu

Tüm servisler özel bir Docker bridge ağı (`inception`) üzerinde çalışır ve dış dünyadan izole edilmiştir.

## ❗ Sorun Giderme

### MariaDB Bağlantı Hatası

```bash
# MariaDB loglarını kontrol edin
docker logs mariadb

# Health check durumunu kontrol edin
docker inspect mariadb | grep -A 10 Health
```

### WordPress Kurulum Sorunu

```bash
# WordPress loglarını kontrol edin
docker logs wordpress

# Volume izinlerini kontrol edin
ls -la /home/$USER/data/wordpress
```

### NGINX 502 Bad Gateway

```bash
# WordPress container'ın çalıştığından emin olun
docker ps

# PHP-FPM'in çalıştığını kontrol edin
docker exec wordpress ps aux | grep php-fpm
```

### SSL Sertifika Uyarısı

Self-signed sertifika kullanıldığı için tarayıcıda güvenlik uyarısı alabilirsiniz. Bu normaldir. "Gelişmiş" seçeneğinden siteye devam edebilirsiniz.

### Volume İzin Hatası

```bash
# Volume dizinlerinin izinlerini düzeltin
sudo chown -R $USER:$USER /home/$USER/data
chmod -R 755 /home/$USER/data
```

## 🔍 Faydalı Docker Komutları

```bash
# Container'lara bağlanma
docker exec -it nginx bash
docker exec -it mariadb sh
docker exec -it wordpress bash

# Volume'ları listeleme
docker volume ls

# Ağları listeleme
docker network ls

# Kaynak kullanımını görme
docker stats

# Tüm servislerin durumunu kontrol etme
docker-compose -f srcs/docker-compose.yml ps
```

## 📚 Referanslar

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [WordPress Documentation](https://wordpress.org/documentation/)
- [WP-CLI Documentation](https://wp-cli.org/)

## 📄 Lisans

Bu proje eğitim amaçlı oluşturulmuştur.

**İzzettin Furkan Özmen** - [@beegash](https://github.com/Beegash)

