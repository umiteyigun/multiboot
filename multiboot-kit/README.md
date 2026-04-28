# Multiboot Kit (USB'ye yazmadan hazirlik)

Bu klasor, macOS uzerinde Ventoy tabanli multiboot USB hazirligi icin olusturuldu.
Bu adimlar USB'ye bir sey yazmaz; sadece dosyalari indirir ve yapilandirmayi hazirlar.

## Icerik

- `prepare_ventoy.sh`: Ventoy paketini indirir, acip `tools/ventoy` altina koyar.
- `manage_isos.sh`: ISO adlarini normalize eder ve `iso-manifest.sha256` olusturur.
- `verify_isos.sh`: `isos/` klasorundeki ISO dosyalarini listeler ve `shasum` uretir.
- `isos/`: Daha sonra USB'ye kopyalayacagin ISO dosyalari.
- `tools/`: Indirilen Ventoy araci burada tutulur.

## 1) Hazirlik

```bash
cd "/Users/umiteyigun/Downloads/arc-3.1.0/multiboot-kit"
chmod +x prepare_ventoy.sh manage_isos.sh verify_isos.sh
./prepare_ventoy.sh
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

## Not

USB'ye yazma islemi bilerek bu hazirlikta yapilmiyor.
Istediginde bir sonraki adimda Ventoy ile diske kurulum komutunu birlikte calistiririz.
