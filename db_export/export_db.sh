#!/bin/bash

# Cargar credenciales
source ./db_credentials.sh

# Función para exportar MongoDB
export_mongodb() {
    echo "Exportando MongoDB..."
    mongodump --host $MONGO_HOST --port $MONGO_PORT --db $MONGO_DB --username $MONGO_USER --password $MONGO_PASS --out dump/
    if [ $? -eq 0 ]; then
        echo "MongoDB exportado exitosamente."
    else
        echo "Error al exportar MongoDB."
        exit 1
    fi
}

# Función para exportar MariaDB
export_mariadb() {
    echo "Exportando MariaDB..."
    mysqldump -h $MARIADB_HOST -P $MARIADB_PORT -u $MARIADB_USER -p$MARIADB_PASS $MARIADB_DB > dump/$MARIADB_DB.sql
    if [ $? -eq 0 ]; then
        echo "MariaDB exportado exitosamente."
    else
        echo "Error al exportar MariaDB."
        exit 1
    fi
}

# Función para exportar PostgreSQL
export_postgresql() {
    echo "Exportando PostgreSQL..."
    PGPASSWORD=$PG_PASS pg_dump -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -F c -b -v -f dump/$PG_DB.dump
    if [ $? -eq 0 ]; then
        echo "PostgreSQL exportado exitosamente."
    else
        echo "Error al exportar PostgreSQL."
        exit 1
    fi
}

# Preguntar por la base de datos
read -p "Seleccione la base de datos a exportar (mongodb/mariadb/postgresql): " DB_TYPE

if [ ! -d "dump" ]; then
    mkdir dump
fi

case $DB_TYPE in
    mongodb)
        export_mongodb
        ;;
    mariadb)
        export_mariadb
        ;;
    postgresql)
        export_postgresql
        ;;
    *)
        echo "Tipo de base de datos no soportado."
        exit 1
        ;;
esac

# Preguntar si desea comprimir
read -p "¿Desea comprimir los archivos exportados? (y/n): " COMPRESS

if [ "$COMPRESS" = "y" ]; then
    echo "Comprimiendo archivos..."
    tar -czvf dump.tar.gz dump/
    if [ $? -eq 0 ]; then
        echo "Archivos comprimidos exitosamente."
        rm -rf dump/
    else
        echo "Error al comprimir los archivos."
        exit 1
    fi
fi

echo "Exportación completada."
