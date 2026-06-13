# Logos CONFIDIA

## Sources (référence design)
- `Confidia-logo-blue.svg` · thème bleu
- `Confidia-logo-pink.svg` · thème rose

Les SVG sources embarquent une image raster (fichiers lourds ~3–5 Mo). **Ils ne sont pas chargés à l'exécution.**

## Assets runtime (optimisés)
| Fichier | Usage |
|---------|--------|
| `confidia-logo-blue-128.png` | Petites tailles (sidebar, top bar) |
| `confidia-logo-blue-256.png` | Grandes tailles (login, splash) |
| `confidia-logo-pink-128.png` | Idem thème rose |
| `confidia-logo-pink-256.png` | Idem thème rose |

# Régénération (fond transparent) depuis le PNG embarqué dans le SVG :
```bash
cd assets/logo
python3 << 'PY'
import base64, re, subprocess, os
for name in ['blue', 'pink']:
    svg = open(f'Confidia-logo-{name}.svg').read()
    raw = base64.b64decode(re.search(r'href="data:image/png;base64,([^"]+)"', svg).group(1))
    tmp = f'_extracted-{name}.png'
    open(tmp, 'wb').write(raw)
    for size in (128, 256):
        subprocess.run(['magick', tmp, '-alpha', 'on', '-fuzz', '12%', '-transparent', 'white',
            '-trim', '+repage', '-resize', f'{size}x{size}', '-background', 'none',
            '-gravity', 'center', '-extent', f'{size}x{size}', 'PNG32:confidia-logo-{name}-{size}.png'], check=True)
    os.remove(tmp)
PY
```

Composants : `ConfidiaLogo`, `ConfidiaLogoMark`, `ConfidiaAnimatedLogo`.
