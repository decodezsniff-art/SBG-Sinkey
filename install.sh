#!/usr/bin/env bash
# Instalador seguro para SBG-Sinkey.
# Por defecto solo descarga y audita; nunca ejecuta código remoto.
set -Eeuo pipefail

REPO="${REPO:-https://github.com/decodezsniff-art/SBG-Sinkey.git}"
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/decodezsniff-art/SBG-Sinkey/main}"
WORKDIR=""

cleanup() {
  if [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]]; then
    rm -rf -- "${WORKDIR}"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Uso:
  ./install.sh                 Descarga y audita; no modifica el sistema.
  ./install.sh --audit-only    Igual que el modo predeterminado.
  ./install.sh --execute-original
                               Ejecuta sbg_nokey.sh como root después de una
                               confirmación escrita explícita. NO recomendado.
  ./install.sh --help          Muestra esta ayuda.

Variables opcionales:
  REPO      URL del repositorio Git de origen.
  RAW_BASE  URL base de los archivos sin procesar.
EOF
}

mode="audit"
case "${1:-}" in
  "") ;;
  --audit-only) mode="audit" ;;
  --execute-original) mode="execute" ;;
  --help|-h) usage; exit 0 ;;
  *) echo "Opción desconocida: $1" >&2; usage >&2; exit 2 ;;
esac

for command in curl sha256sum bash grep file; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "Falta una dependencia requerida: $command" >&2
    exit 1
  }
done

if [[ "$mode" == "execute" && "$(id -u)" -ne 0 ]]; then
  echo "--execute-original requiere root. El modo de auditoría no." >&2
  exit 1
fi

WORKDIR="$(mktemp -d -t sbg-sinkey-audit.XXXXXX)"
readonly TARGET="$WORKDIR/sbg_nokey.sh"
readonly SECONDARY="$WORKDIR/sbg2_nokey.sh"
readonly ARCHIVE="$WORKDIR/SBG.zip"

echo "Repositorio: $REPO"
echo "Descargando archivos para auditoría en: $WORKDIR"

curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
  "$RAW_BASE/sbg_nokey.sh" --output "$TARGET"
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
  "$RAW_BASE/sbg2_nokey.sh" --output "$SECONDARY"
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
  "$RAW_BASE/SBG.zip" --output "$ARCHIVE"

chmod 600 "$TARGET" "$SECONDARY" "$ARCHIVE"

if file "$TARGET" "$SECONDARY" "$ARCHIVE" | grep -q 'ELF'; then
  echo "Se detectó un binario ELF inesperado; se cancela." >&2
  exit 1
fi

if ! bash -n "$TARGET"; then
  echo "Error de sintaxis en sbg_nokey.sh; se cancela." >&2
  exit 1
fi
if ! bash -n "$SECONDARY"; then
  echo "Error de sintaxis en sbg2_nokey.sh; se cancela." >&2
  exit 1
fi

printf '\nSHA-256 de los artefactos descargados:\n'
sha256sum "$TARGET" "$SECONDARY" "$ARCHIVE"

printf '\nAcciones de alto riesgo detectadas en los scripts:\n'
grep -nE '(^|[[:space:]])(rm[[:space:]]+-rf|iptables[[:space:]]+-F|chpasswd|PasswordAuthentication[[:space:]]+yes|PermitRootLogin|reboot|curl .*\|.*bash|wget .*\|.*bash|history -cw|HISTFILE|apt-get (remove|purge)|systemctl)' \
  "$TARGET" "$SECONDARY" || true

cat <<'EOF'

AUDITORÍA TERMINADA.
No se ha ejecutado ningún script y no se ha modificado el sistema.
Los hashes identifican esta descarga, pero no demuestran que el código sea seguro.
EOF

if [[ "$mode" == "audit" ]]; then
  exit 0
fi

cat <<'EOF'

ADVERTENCIA FINAL:
El instalador original modifica SSH, firewall, paquetes, contraseña de root,
historial y servicios; además descarga y ejecuta más código. Puede bloquear el
servidor o dejarlo expuesto. Ejecutarlo puede causar pérdida de acceso y datos.
EOF

printf '\nPara continuar escribe exactamente: EJECUTAR ORIGINAL EN ESTE SERVIDOR\n> '
IFS= read -r confirmation
if [[ "$confirmation" != "EJECUTAR ORIGINAL EN ESTE SERVIDOR" ]]; then
  echo "Confirmación incorrecta. No se ejecutó nada."
  exit 0
fi

# La ejecución explícita es local, pero el script original puede descargar más
# componentes remotos. La confirmación anterior es intencionalmente inequívoca.
echo "Ejecutando sbg_nokey.sh como root por solicitud explícita..."
exec bash "$TARGET"
