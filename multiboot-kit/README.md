# Multiboot Kit (USB'ye yazmadan hazirlik)

Bu klasor, macOS uzerinde Ventoy tabanli multiboot USB hazirligi icin olusturuldu.
Bu adimlar USB'ye bir sey yazmaz; sadece dosyalari indirir ve yapilandirmayi hazirlar.

## Icerik

- `prepare_ventoy.sh`: Ventoy paketini indirir, acip `tools/ventoy` altina koyar.
- `manage_isos.sh`: ISO adlarini normalize eder ve `iso-manifest.sha256` olusturur.
- `verify_isos.sh`: `isos/` klasorundeki ISO dosyalarini listeler ve `shasum` uretir.
- `install_ventoy_to_usb.sh`: USB diske Ventoy kurar (Linux'ta otomatik).
- `copy_isos_to_usb.sh`: `isos/` klasorundeki ISO dosyalarini Ventoy USB'ye kopyalar.
- `run_all.sh`: Tum adimlari tek akista calistirir (opsiyonel Ventoy kurulum + ISO kopyalama).
- `Dockerfile`: Platform bagimsiz calisma ortami.
- `docker-run.sh`: Docker icinde tek komutla calistirma wrapper'i.
- `full_auto.sh`: OS tespit + Docker build + OS'e gore otomatik akisi yonetir.
- `isos/`: Daha sonra USB'ye kopyalayacagin ISO dosyalari.
- `tools/`: Indirilen Ventoy araci burada tutulur.

## 1) Hazirlik

```bash
cd "/Users/umiteyigun/Downloads/arc-3.1.0/multiboot-kit"
chmod +x prepare_ventoy.sh manage_isos.sh verify_isos.sh install_ventoy_to_usb.sh copy_isos_to_usb.sh run_all.sh docker-run.sh
./prepare_ventoy.sh
```

## Tam otomasyon (OS tespitli)

```bash
chmod +x full_auto.sh
./full_auto.sh --disk disk4
```

`full_auto.sh` davranisi:
- OS tespit eder
- Docker image build eder
- Docker icinde ortak adimlari (prepare/manage/verify) calistirir
- Linux'ta Ventoy kurulum + ISO kopyalamayi otomatik dener
- macOS'ta Ventoy kurulumunu atlar, host tarafinda ISO kopyalar

## Docker ile full otomasyon (onerilen)

Host fark etmeksizin ayni akisi Docker ile calistirabilirsin:

```bash
cd "/Users/umiteyigun/Downloads/arc-3.1.0/multiboot-kit"
./docker-run.sh
```

Ventoy kurulum + ISO kopyalama:

```bash
./docker-run.sh --install-ventoy --copy-isos --auto --yes
```

## 2) ISO dosyalarini ekle

ISO dosyalarini `isos/` klasorune kopyala.

Ornek:

```bash
cp ~/Downloads/*.iso ./isos/
```

## 3) ISO yonetimi (onerilir)

```bash
./manage_isos.sh
```

Bu komut:
- ISO adlarini sade/gucvenli formata cevirir (bosluk/ozel karakterleri temizler)
- Ayni ad cakismasinda `-1`, `-2` eki verir
- `iso-manifest.sha256` dosyasini uretir

## 4) ISO kontrolu (opsiyonel ama onerilir)

```bash
./verify_isos.sh
```

Bu komut:
- ISO listesini yazdirir
- Her ISO icin SHA256 ozeti cikarir
- Manifest varsa `shasum -c` ile dogrulama yapar

## Ventoy kurulum + ISO kopyalama

### Tek komutta otomatik akis

```bash
./run_all.sh --install-ventoy --copy-isos --auto
```

Bu komut sirasiyla:
1) prepare
2) manage
3) verify
4) Ventoy kurulum
5) ISO kopyalama

### Ayrik komutlar

```bash
./install_ventoy_to_usb.sh --auto
./copy_isos_to_usb.sh --disk disk4
```

## Onemli not (macOS)

Ventoy'nin resmi installer'i macOS icin yok. Bu nedenle:
- `prepare_ventoy.sh` macOS'ta calisir (indirir/hazirlar)
- Ventoy kurulum adimi Linux/Windows ortaminda otomatik calisir
- `copy_isos_to_usb.sh` macOS'ta Ventoy bolumu mounted ise ISO kopyalar
- Docker Desktop uzerinden USB raw-device erisimi kisitli olabilir; bu durumda Ventoy kurulumunu Linux host/VM icinde calistir.
