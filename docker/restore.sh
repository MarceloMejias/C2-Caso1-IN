#!/bin/bash
# ==============================================================================
# Script de inicio rápido y restauración de la base de datos en Docker
# EXCLUSIVO para entornos macOS (Apple Silicon ARM64 / Intel) y Linux
# Los usuarios en Windows 11 deben restaurar directamente Albarran.bak vía SSMS
# ==============================================================================

set -e

# Cambiar al directorio del script
cd "$(dirname "$0")"

# 1. Cargar variables de entorno desde .env (en la raíz del proyecto)
ENV_FILE="../.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "❌ Error: La variable DB_PASSWORD no está definida."
    echo "   Por favor crea o configura el archivo .env en la raíz del proyecto antes de continuar."
    exit 1
fi

DB_USER="${DB_USER:-sa}"
DB_PORT="${DB_PORT:-1433}"
DB_NAME="${DB_NAME:-Albarran}"

echo "=========================================================="
echo "  Mueblería Albarrán - Entorno Docker SQL Server 2022"
echo "=========================================================="

# 2. Verificar si Docker está ejecutándose
if ! docker info >/dev/null 2>&1; then
    echo "⚠️  Docker daemon no está corriendo. Intentando abrir Docker Desktop..."
    open -a Docker || true
    echo "Esperando a que Docker Desktop inicie..."
    while ! docker info >/dev/null 2>&1; do
        sleep 2
    done
    echo "✅ Docker Desktop está activo."
fi

# 3. Levantar el contenedor
echo "🚀 Levantando contenedor de SQL Server..."
docker compose up -d

# 4. Esperar a que SQL Server esté listo para aceptar conexiones
echo "⏳ Esperando disponibilidad de SQL Server..."
until docker exec sqlserver_albarran /opt/mssql-tools18/bin/sqlcmd -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -C -Q "SELECT 1" >/dev/null 2>&1 || \
      docker exec sqlserver_albarran /opt/mssql-tools/bin/sqlcmd -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -Q "SELECT 1" >/dev/null 2>&1; do
    echo "   ... inicializando motor ..."
    sleep 3
done

echo "✅ SQL Server está listo para recibir comandos."

# 5. T-SQL para restaurar directamente Albarran.bak dentro del contenedor
RESTORE_SQL="
USE master;
IF EXISTS (SELECT name FROM sys.databases WHERE name = '$DB_NAME')
BEGIN
    ALTER DATABASE [$DB_NAME] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$DB_NAME];
END;
RESTORE DATABASE [$DB_NAME]
FROM DISK = '/var/opt/mssql/backup/Albarran.bak'
WITH 
    MOVE 'Albarran1' TO '/var/opt/mssql/data/Albarran.mdf',
    MOVE 'Albarran1_log' TO '/var/opt/mssql/data/Albarran_log.ldf',
    REPLACE, RECOVERY, STATS = 10;
"

echo "📦 Restaurando base de datos $DB_NAME desde /var/opt/mssql/backup/Albarran.bak..."
if docker exec sqlserver_albarran test -f /opt/mssql-tools18/bin/sqlcmd; then
    docker exec sqlserver_albarran /opt/mssql-tools18/bin/sqlcmd -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -C -Q "$RESTORE_SQL"
else
    docker exec sqlserver_albarran /opt/mssql-tools/bin/sqlcmd -S localhost -U "$DB_USER" -P "$DB_PASSWORD" -Q "$RESTORE_SQL"
fi

echo "=========================================================="
echo "🎉 ¡Base de datos $DB_NAME restaurada correctamente en Docker!"
echo "   Host:     localhost:$DB_PORT"
echo "   Usuario:  $DB_USER"
echo "   Password: [Configurada en .env]"
echo "   Database: $DB_NAME"
echo "=========================================================="
