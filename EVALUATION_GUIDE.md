# 🎯 INCEPTION PROJECT - EVALUATION GUIDE

## 📋 İçindekiler

1. [Başlamadan Önce](#1-başlamadan-önce)
2. [Preliminary Tests](#2-preliminary-tests---docker-temizliği)
3. [General Instructions](#3-general-instructions---yapı-kontrolü)
4. [Projeyi Başlat](#4-projeyi-başlat)
5. [Project Overview](#5-project-overview---açıklamalar)
6. [Simple Setup](#6-simple-setup---nginx-ve-wordpress)
7. [Docker Basics](#7-docker-basics)
8. [Docker Network](#8-docker-network)
9. [NGINX with SSL/TLS](#9-nginx-with-ssltls)
10. [WordPress with php-fpm](#10-wordpress-with-php-fpm)
11. [MariaDB and Volume](#11-mariadb-and-volume)
12. [Persistence Test](#12-persistence-test---reboot)
13. [Özet Komutları](#13-özet-komutları---hızlı-kontrol)
14. [Değerlendirme Checklist](#14-değerlendirme-checklist)

---

## 1. Başlamadan Önce

### Git Repository Kontrolü

```bash
# Repository'yi clone et
cd ~/
git clone [GIT_REPO_URL]
cd inception/

# .env dosyası ve secrets kontrolü
cat srcs/.env 2>/dev/null || echo ".env dosyası secrets klasöründe olmalı"
ls -la srcs/requirements/nginx/conf/ssl/
cat project/secrets/*.txt
```

**⚠️ ÖNEMLI:** Herhangi bir credential veya API key Git'te açıkta olmamalı. `.env` dosyası ve secrets dosyaları evaluation sırasında oluşturulmalı.

---

## 2. Preliminary Tests - Docker Temizliği

### Docker'ı Tamamen Temizle

```bash
cd ~/inception/project/

# Evaluator'ın istediği komut (tek satır)
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null

# VEYA Makefile ile
make fclean
```

**Açıklama:** Temiz bir başlangıç için tüm Docker kaynakları silinir.

---

## 3. General Instructions - Yapı Kontrolü

### 3.1. Dizin Yapısını Kontrol Et

```bash
# Dizin yapısını göster
tree -L 3 .

# Beklenen yapı:
# project/
# ├── Makefile
# ├── secrets/
# └── srcs/
#     ├── docker-compose.yml
#     ├── .env
#     └── requirements/
#         ├── mariadb/
#         ├── nginx/
#         └── wordpress/
```

### 3.2. docker-compose.yml Kontrolü

```bash
# ❌ YASAKLI: 'network: host' veya 'links:' OLMAMALI
cat srcs/docker-compose.yml | grep -E "network:.*host|links:"
# Çıktı boş olmalı!

# ✅ ZORUNLU: network(s) tanımlanmalı
cat srcs/docker-compose.yml | grep -A5 "^networks:"
# Networks bölümü görülmeli
```

**Kontrol Noktaları:**
- ❌ `network: host` yasak
- ❌ `links:` yasak  
- ✅ `networks:` zorunlu

### 3.3. Makefile ve Script Kontrolü

```bash
# '--link' OLMAMALI
grep -r "\-\-link" Makefile srcs/
# Çıktı boş olmalı!
```

### 3.4. Dockerfile Kontrolü

```bash
# Her servis için Dockerfile kontrol et
cat srcs/requirements/nginx/Dockerfile
cat srcs/requirements/wordpress/Dockerfile
cat srcs/requirements/mariadb/Dockerfile

# ❌ ENTRYPOINT'te background process OLMAMALI
grep -E "tail -f|sleep infinity|tail -f /dev/null" srcs/requirements/*/Dockerfile
# Çıktı boş olmalı!

# ✅ Base image kontrol (alpine veya debian penultimate version)
grep "^FROM" srcs/requirements/*/Dockerfile
# alpine:3.21 veya debian:bookworm olmalı
```

**Yasaklı Komutlar:**
- ❌ `tail -f`
- ❌ `sleep infinity`
- ❌ `nginx & bash`
- ❌ Background process'ler

---

## 4. Projeyi Başlat

### Makefile ile Build ve Start

```bash
cd ~/inception/project/

# Projeyi başlat
make

# Alternatif
docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build
```

---

## 5. Project Overview - Açıklamalar

### 5.1. Docker ve docker-compose Nasıl Çalışır?

**Açıklama:**
```
Docker: Container'ları izole ortamlarda çalıştırır. Her container bir image'dan oluşturulur.

docker-compose: Birden fazla container'ı bir arada yönetir. 
- docker-compose.yml ile tüm servisleri tanımlarız
- Tek komutla (docker-compose up) hepsini başlatırız
- Network, volume, environment variable'ları kolayca yönetir
```

### 5.2. Docker Image docker-compose ile/olmadan Kullanımı

**Açıklama:**
```
Docker-compose OLMADAN:
  docker run -d --name nginx -p 443:443 nginx_image
  docker run -d --name wordpress --link nginx wordpress_image
  Her container manuel oluşturulur, network manuel yapılandırılır

Docker-compose İLE:
  docker-compose up -d
  Tüm servisleri, network'leri, volume'ları otomatik yapar
```

### 5.3. Docker vs VM Avantajı

**Açıklama:**
```
Docker:
  + Hafif (MB seviyesi)
  + Hızlı başlatma (saniyeler)
  + Kaynak verimli (host kernel paylaşır)
  + Taşınabilir (her yerde çalışır)

VM:
  - Ağır (GB seviyesi)
  - Yavaş başlatma (dakikalar)
  - Her VM kendi kernel'ını çalıştırır
```

### 5.4. Dizin Yapısının Önemi

**Açıklama:**
```
srcs/
  ├── docker-compose.yml    # Tüm servisleri orchestrate eder
  ├── .env                  # Environment variables
  └── requirements/         # Her servis için ayrı klasör
      ├── nginx/
      │   ├── Dockerfile    # Nginx image'ını build eder
      │   └── conf/         # Nginx konfigürasyonu
      ├── wordpress/
      └── mariadb/

Bu yapı:
- Her servisi izole eder
- Dockerfile'ları organize eder
- Konfigürasyonları merkezi tutar
```

---

## 6. Simple Setup - NGINX ve WordPress

### 6.1. /etc/hosts Kontrolü

```bash
# Domain eklenmiş mi?
cat /etc/hosts | grep iozmen.42.fr

# Yoksa ekle (sudo gerekli)
echo "127.0.0.1 iozmen.42.fr" | sudo tee -a /etc/hosts
```

### 6.2. NGINX Port Kontrolü

```bash
# NGINX sadece 443'te olmalı (80 kapalı)
docker ps | grep nginx

# Port 443 dinliyor mu?
ss -tlnp | grep 443

# Port 80 KAPALI olmalı (bağlanamamalı)
curl http://iozmen.42.fr
# Connection refused olmalı
```

### 6.3. SSL/TLS Sertifikası Kontrolü

```bash
# SSL sertifikası kontrol
openssl s_client -connect iozmen.42.fr:443 -showcerts

# Sertifika bilgilerini göster
openssl x509 -in srcs/requirements/nginx/conf/ssl/server.crt -text -noout
```

### 6.4. WordPress Erişimi

**Tarayıcıda Test:**
```
https://iozmen.42.fr

✅ WordPress ana sayfası açılmalı
✅ Kilit ikonu görünmeli (self-signed warning normal)
❌ WordPress kurulum sayfası GÖRÜNMEMELİ

http://iozmen.42.fr
❌ Erişilemez olmalı
```

---

## 7. Docker Basics

### 7.1. Container ve Image Kontrolü

```bash
# Container'ları listele
docker ps

# Beklenen çıktı:
# nginx
# wordpress
# mariadb (healthy)

# Image'ları listele
docker images

# Image isimleri servis isimleriyle aynı olmalı:
# srcs_nginx
# srcs_wordpress  
# srcs_mariadb

# Docker-compose ile mi başlatıldı?
docker-compose -f srcs/docker-compose.yml ps
```

**Açıklama:** Her servis için kendi Dockerfile'dan build edilmiş image olmalı. DockerHub'dan hazır image yasak!

---

## 8. Docker Network

### 8.1. Network Kontrolü

```bash
# Network'ü listele
docker network ls

# 'inception' veya benzeri network görünmeli
docker network ls | grep inception

# Network detayları
docker network inspect srcs_inception

# Container'lar aynı network'te mi?
docker network inspect srcs_inception | grep -A5 "Containers"
```

**Açıklama:** "Docker network, container'ların birbirleriyle izole bir şekilde iletişim kurmasını sağlar. Container'lar servis ismiyle birbirlerine erişir (örn: wordpress → mariadb)."

### 8.2. Network İletişim Testi

```bash
# Nginx container'ından WordPress'e ping
docker exec nginx ping wordpress -c 3

# WordPress container'ından MariaDB'ye ping
docker exec wordpress ping mariadb -c 3
```

---

## 9. NGINX with SSL/TLS

### 9.1. NGINX Dockerfile Kontrolü

```bash
# Dockerfile var mı?
ls -la srcs/requirements/nginx/Dockerfile

# Nginx Dockerfile içeriğini göster
cat srcs/requirements/nginx/Dockerfile
```

### 9.2. NGINX Container Kontrolü

```bash
# Container çalışıyor mu?
docker-compose -f srcs/docker-compose.yml ps nginx

# Nginx process kontrolü
docker exec nginx ps aux | grep nginx
```

### 9.3. Port Erişim Testi

```bash
# HTTP (port 80) bağlantısı BAŞARISIZ olmalı
curl http://iozmen.42.fr
# curl: (7) Failed to connect

# HTTPS (port 443) BAŞARILI olmalı
curl -k https://iozmen.42.fr
# WordPress HTML görünmeli
```

### 9.4. SSL/TLS Versiyonu Kontrolü

```bash
# TLSv1.2 veya TLSv1.3 kullanılıyor mu?
openssl s_client -connect iozmen.42.fr:443 -tls1_2
# Protocol: TLSv1.2 görünmeli

openssl s_client -connect iozmen.42.fr:443 -tls1_3
# Protocol: TLSv1.3 görünmeli

# Nginx config kontrolü
docker exec nginx cat /etc/nginx/conf.d/default.conf | grep ssl_protocols
# TLSv1.2 TLSv1.3 olmalı
```

### 9.5. Tarayıcı SSL Testi

```
1. https://iozmen.42.fr adresine git
2. Kilit ikonuna tıkla
3. Sertifika bilgilerini gör
4. Self-signed olabilir (normal)
5. WordPress sayfası açılmalı
```

---

## 10. WordPress with php-fpm

### 10.1. WordPress Dockerfile Kontrolü

```bash
# Dockerfile var mı?
ls -la srcs/requirements/wordpress/Dockerfile

# ❌ NGINX OLMAMALI Dockerfile'da
cat srcs/requirements/wordpress/Dockerfile | grep -i nginx
# Çıktı boş olmalı!

# ✅ PHP-FPM olmalı
cat srcs/requirements/wordpress/Dockerfile | grep -i php-fpm
```

### 10.2. WordPress Container Kontrolü

```bash
# Container çalışıyor mu?
docker-compose -f srcs/docker-compose.yml ps wordpress

# PHP-FPM çalışıyor mu?
docker exec wordpress ps aux | grep php-fpm
```

### 10.3. WordPress Volume Kontrolü

```bash
# Volume'ları listele
docker volume ls

# srcs_wordpress_data görünmeli
docker volume ls | grep wordpress

# Volume detayları
docker volume inspect srcs_wordpress_data

# Mountpoint /home/iozmen/data/wordpress olmalı
docker volume inspect srcs_wordpress_data | grep Mountpoint

# Data dizini kontrol
ls -la /home/iozmen/data/wordpress/
# WordPress dosyaları görünmeli (wp-config.php, wp-content/, etc.)
```

### 10.4. WordPress'e Yorum Ekleme Testi

**Tarayıcıda:**
```
1. https://iozmen.42.fr adresine git
2. Bir post'a tıkla
3. Yorum yaz
4. Yorum göründü mü kontrol et
```

### 10.5. WordPress Admin Dashboard

```bash
# Admin paneline giriş
# https://iozmen.42.fr/wp-admin

# Kullanıcı bilgileri (.env dosyasından)
cat srcs/.env | grep WP_ADMIN

# ⚠️ Admin kullanıcı adı kontrol
# ❌ "admin", "Admin", "administrator" yasak
# ✅ "iozmen", "user42", vs. olmalı
```

**Tarayıcı Testi:**
```
1. https://iozmen.42.fr/wp-admin adresine git
2. Admin ile giriş yap
   Username: (admin OLMAYAN bir isim)
   Password: (secrets dosyasından)
3. Dashboard açılmalı
4. Pages → Bir sayfayı düzenle
5. Kaydet
6. Site'de değişiklik görünmeli
```

### 10.6. WordPress Kullanıcıları Kontrol

```bash
# WordPress container'ına gir
docker exec -it wordpress bash

# WP-CLI ile kullanıcıları listele
wp user list --allow-root

# Beklenen: 2 kullanıcı
# 1. Admin (admin isminde OLMAMALI)
# 2. İkinci kullanıcı (editor, author, vs.)

# Çıkış
exit
```

---

## 11. MariaDB and Volume

### 11.1. MariaDB Dockerfile Kontrolü

```bash
# Dockerfile var mı?
ls -la srcs/requirements/mariadb/Dockerfile

# ❌ NGINX OLMAMALI
cat srcs/requirements/mariadb/Dockerfile | grep -i nginx
# Çıktı boş olmalı!
```

### 11.2. MariaDB Container Kontrolü

```bash
# Container çalışıyor mu?
docker-compose -f srcs/docker-compose.yml ps mariadb

# Healthy durumda mı?
docker ps | grep mariadb
# STATUS: Up X seconds (healthy)

# MariaDB process
docker exec mariadb ps aux | grep mysql
```

### 11.3. MariaDB Volume Kontrolü

```bash
# Volume listele
docker volume ls | grep mariadb

# Volume detayları
docker volume inspect srcs_mariadb_data

# Mountpoint /home/iozmen/data/mariadb olmalı
docker volume inspect srcs_mariadb_data | grep Mountpoint

# Data dizini kontrol
ls -la /home/iozmen/data/mariadb/
# MySQL dosyaları görünmeli (ibdata1, mysql/, wordpress/, etc.)
```

### 11.4. MariaDB'ye Giriş ve Database Kontrolü

```bash
# MariaDB container'ına gir
docker exec -it mariadb bash

# Root ile giriş
mysql -uroot -p
# Şifre: (secrets/db_root_password.txt dosyasından)

# Veritabanlarını listele
SHOW DATABASES;
# wordpress database görünmeli

# WordPress veritabanını kullan
USE wordpress;

# Tabloları listele
SHOW TABLES;
# wp_posts, wp_users, wp_options, etc. görünmeli

# Kullanıcıları kontrol
SELECT User, Host FROM mysql.user;
# root, wpuser görünmeli

# WordPress postları kontrol
SELECT * FROM wp_posts WHERE post_type='post' LIMIT 5;

# Çıkış
EXIT;
exit
```

**Alternatif Komut:**
```bash
# Tek satırda database kontrol
docker exec mariadb mysql -uroot -p$(cat project/secrets/db_root_password.txt) -e "SHOW DATABASES;"
```

---

## 12. Persistence Test - Reboot

### Değişiklik Yap ve Reboot

```bash
# 1. WordPress'te değişiklik yap
# https://iozmen.42.fr/wp-admin
# → Yeni bir post ekle veya mevcut sayfayı düzenle

# 2. Container'ları durdur
cd ~/inception/project/
docker-compose -f srcs/docker-compose.yml down

# 3. VM'i reboot et
sudo reboot

# 4. VM başladıktan sonra tekrar başlat
cd ~/inception/project/
make

# 5. WordPress'i kontrol et
# https://iozmen.42.fr
# → Yaptığın değişiklikler hala durmalı!

# 6. Database kontrol
docker exec -it mariadb mysql -uroot -p -e "USE wordpress; SELECT post_title FROM wp_posts WHERE post_type='post';"
# Postlar kaybolmamış olmalı
```

**Açıklama:** Volume'lar sayesinde container silinse bile veriler korunur.

---

## 13. Özet Komutları - Hızlı Kontrol

```bash
# Tüm kontroller tek başına
cd ~/inception/project/

# 1. Docker temizliği
make fclean

# 2. Yapı kontrolü
cat srcs/docker-compose.yml | grep -E "network:.*host|links:"  # Boş olmalı
grep "^FROM" srcs/requirements/*/Dockerfile                     # alpine/debian

# 3. Projeyi başlat
make

# 4. Container'ları kontrol
docker ps                                    # 3 container UP
docker-compose -f srcs/docker-compose.yml ps # nginx, wordpress, mariadb

# 5. Network kontrol
docker network ls | grep inception           # Network var
docker exec nginx ping wordpress -c 2        # İletişim OK

# 6. NGINX kontrol
curl http://iozmen.42.fr                     # BAŞARISIZ (80 kapalı)
curl -k https://iozmen.42.fr                 # BAŞARILI (443 açık)
openssl s_client -connect iozmen.42.fr:443   # TLS v1.2/1.3

# 7. Volume kontrol
docker volume ls                             # 2 volume
docker volume inspect srcs_wordpress_data    # /home/iozmen/data/
docker volume inspect srcs_mariadb_data      # /home/iozmen/data/

# 8. WordPress kontrol
docker exec wordpress wp user list --allow-root  # 2 kullanıcı

# 9. MariaDB kontrol
docker exec mariadb mysql -uroot -p -e "SHOW DATABASES;"

# 10. Reboot testi
docker-compose -f srcs/docker-compose.yml down
sudo reboot
# Başladıktan sonra: make
# → Veriler korunmuş olmalı
```

---

## 14. Değerlendirme Checklist

### Preliminary Tests
- [ ] Git'te credential yok
- [ ] Docker tamamen temizlendi
- [ ] srcs/ dizini var
- [ ] Makefile var

### General Instructions
- [ ] docker-compose.yml'de `network: host` ve `links:` yok
- [ ] docker-compose.yml'de `networks:` var
- [ ] Makefile ve scriptlerde `--link` yok
- [ ] Dockerfile'larda `tail -f`, `sleep infinity` yok
- [ ] Dockerfile'lar alpine/debian penultimate version

### Docker Basics
- [ ] `make` çalışıyor
- [ ] 3 container UP (nginx, wordpress, mariadb)
- [ ] Her servis için Dockerfile var
- [ ] Image isimleri servis isimleriyle aynı
- [ ] Hazır image kullanılmamış (DockerHub yasak)

### Simple Setup
- [ ] Port 80 kapalı
- [ ] Port 443 açık
- [ ] HTTPS çalışıyor
- [ ] SSL sertifikası var
- [ ] TLSv1.2 veya TLSv1.3 kullanılıyor
- [ ] WordPress kurulu (kurulum sayfası yok)

### WordPress
- [ ] WordPress Dockerfile'da NGINX yok
- [ ] Admin kullanıcı adı "admin" değil
- [ ] 2 WordPress kullanıcısı var
- [ ] Yorum eklenebiliyor
- [ ] Admin dashboard'dan sayfa düzenlenebiliyor

### Network
- [ ] Docker network çalışıyor
- [ ] Container'lar birbirleriyle iletişim kurabiliyor

### Volumes
- [ ] 2 volume var (wordpress, mariadb)
- [ ] Volume mountpoint `/home/login/data/` içinde
- [ ] WordPress volume çalışıyor
- [ ] MariaDB volume çalışıyor

### MariaDB
- [ ] MariaDB Dockerfile'da NGINX yok
- [ ] MariaDB'ye giriş yapılabiliyor
- [ ] Database dolu (tablolar var)
- [ ] Kullanıcılar doğru (root, wpuser)

### Persistence
- [ ] Reboot sonrası container'lar otomatik başlıyor
- [ ] Reboot sonrası veriler korunuyor
- [ ] WordPress değişiklikleri kaybolmuyor
- [ ] MariaDB verileri kaybolmuyor

---

## 🎓 Değerlendirme İpuçları

### Evaluator'a Açıklama Yaparken

1. **Basit ve anlaşılır ol**: Teknik terimleri açıkla
2. **Örnek ver**: "Docker lightweight çünkü host kernel'ı paylaşır"
3. **Göster**: Sadece anlat değil, komutları çalıştır
4. **Sorularını cevapla**: Emin olmadığın yerler için dürüst ol

### Yaygın Hatalar

❌ Port 80 açık bırakmak  
❌ Admin kullanıcı adı "admin" yapmak  
❌ Hazır image kullanmak (DockerHub)  
❌ Şifreleri Dockerfile'a yazmak  
❌ `latest` tag kullanmak  
❌ Volume'ları yanlış konumda mount etmek  
❌ Network tanımlamamak  

### Başarı İçin

✅ Tüm komutları önceden test et  
✅ Reboot sonrası her şeyin çalıştığından emin ol  
✅ Dockerfile'ları açıklayabilir ol  
✅ Docker network kavramını anla  
✅ Volume persistence'ı göster  
✅ SSL/TLS sertifikasını açıkla  

---

## 📚 Ek Kaynaklar

### Faydalı Komutlar

```bash
# Log kontrolü
docker logs nginx
docker logs wordpress
docker logs mariadb

# Container içine giriş
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash

# Servis restart
docker-compose -f srcs/docker-compose.yml restart

# Belirli bir servisi restart
docker-compose -f srcs/docker-compose.yml restart nginx
```

### Troubleshooting

**Problem: Container başlamıyor**
```bash
docker logs [container_name]
```

**Problem: Network iletişimi yok**
```bash
docker network inspect srcs_inception
```

**Problem: Volume mount edilmiyor**
```bash
docker volume inspect [volume_name]
ls -la /home/iozmen/data/
```

**Problem: SSL sertifikası çalışmıyor**
```bash
openssl s_client -connect iozmen.42.fr:443
docker exec nginx ls -la /etc/nginx/ssl/
```

---

## ✨ Son Kontrol

Evaluasyon'dan önce:

1. ✅ VM'i reboot et ve her şeyin çalıştığını kontrol et
2. ✅ Tüm komutları test et
3. ✅ Dockerfile'ları oku ve açıklayabilir ol
4. ✅ Docker kavramlarını anla (network, volume, image vs container)
5. ✅ SSL/TLS'i açıklayabilir ol
6. ✅ WordPress ve MariaDB'nin nasıl iletişim kurduğunu bil

---

**İYİ ŞANSLAR! 🚀**

