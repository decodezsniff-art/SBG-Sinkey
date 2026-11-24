# SBG-Sinkey

Copia del repositorio `DarkFull0726/sbg-sin-key`.

## Instalador seguro

El archivo [`install.sh`](./install.sh) funciona en modo auditoría por defecto. Descarga `sbg_nokey.sh`, `sbg2_nokey.sh` y `SBG.zip` en un directorio temporal, calcula sus SHA-256, comprueba la sintaxis de los scripts y muestra comandos de alto riesgo. **No ejecuta los scripts ni modifica el sistema en el modo predeterminado.**

Requisitos: Linux, Bash, `curl`, `sha256sum`, `file` y `grep`.

```bash
curl -fsSL --proto '=https' --tlsv1.2 \
  https://raw.githubusercontent.com/decodezsniff-art/SBG-Sinkey/main/install.sh \
  -o install.sh
bash install.sh --audit-only
```

También puedes clonar el repositorio y ejecutarlo localmente:

```bash
git clone https://github.com/decodezsniff-art/SBG-Sinkey.git
cd SBG-Sinkey
bash install.sh
```

### Ejecución del instalador original

No se recomienda usar esta opción. El script original modifica SSH, `iptables`, paquetes, servicios, la contraseña de `root` y el historial de comandos. También descarga y ejecuta componentes adicionales. Si aun así decides ejecutarlo en un servidor desechable y con consola de recuperación disponible:

```bash
sudo bash install.sh --execute-original
```

La opción exige root y una confirmación escrita exacta. La confirmación no convierte el código original en seguro; solo evita que se ejecute accidentalmente.

## Advertencia

Los hashes mostrados por el instalador sirven para identificar una descarga concreta, pero no son una firma de confianza. Para producción, revisa el código, fija hashes publicados por una fuente confiable y prueba primero en una máquina aislada. No uses estos scripts en un servidor que contenga datos o credenciales importantes.
