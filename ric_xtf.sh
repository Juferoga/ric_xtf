#!/bin/bash

# Variables de entorno necesarias
# ORIGIN_DB_HOST, ORIGIN_DB_DATABASE, ORIGIN_DB_USER, ORIGIN_DB_PASSWORD, ORIGIN_DB_PORT
# DESTINATION_DB_HOST, DESTINATION_DB_DATABASE, DESTINATION_DB_USER, DESTINATION_DB_PASSWORD, DESTINATION_DB_PORT

# Existencia de variables de ent.
required_vars=("ORIGIN_DB_HOST" "ORIGIN_DB_DATABASE" "ORIGIN_DB_USER" "ORIGIN_DB_PASSWORD" "ORIGIN_DB_PORT" "DESTINATION_DB_HOST" "DESTINATION_DB_DATABASE" "DESTINATION_DB_USER" "DESTINATION_DB_PASSWORD" "DESTINATION_DB_PORT")

for var in "${required_vars[@]}"; do
  if [ -z ${!var} ]; then
    echo "Error: La variable de entorno $var no está definida."
    exit 1
  fi
done

# Función para ejecutar un comando SQL en la base de datos origen y exportar los resultados a un archivo CSV
execute_sql_origin() {
    local sql="$1"
    local output_file="$2"
    PGPASSWORD="$ORIGIN_DB_PASSWORD" psql -h "$ORIGIN_DB_HOST" -U "$ORIGIN_DB_USER" -d "$ORIGIN_DB_DATABASE" -p "$ORIGIN_DB_PORT" -c "$sql" -o "$output_file"
}

# Función para importar datos desde un archivo CSV a la base de datos destino
import_csv_to_destination() {
    local csv_file="$1"
    local destination_table="$2"
    PGPASSWORD="$DESTINATION_DB_PASSWORD" psql -h "$DESTINATION_DB_HOST" -U "$DESTINATION_DB_USER" -d "$DESTINATION_DB_DATABASE" -p "$DESTINATION_DB_PORT" -c "\copy $destination_table FROM '$csv_file' WITH CSV HEADER"
}

# Función para ejecutar un programa Java
execute_java_program() {
    local jar_path="$1"
    local arguments="$2"
    java -jar "$jar_path" $arguments
}

# Función para comprimir archivos en formato ZIP
compress_files() {
    local output_zip_file="$1"
    shift 1 # Eliminar 1 arg (nombre)
    local files_to_compress=("$@")
    zip "$output_zip_file" "${files_to_compress[@]}"
}

# Comprobar parámetros de entrada
# se reciben como parámetros 
if [ "$#" -eq 0 ]; then
  echo "Error: No se han proporcionado esquemas como argumentos."
  exit 1
fi

schemas=("$@")

# Definiendo las rutas y archivos java 
jar_path="./validator.jar"
jar_arguments="-v"
execute_java_program "$jar_path" "$jar_arguments"

# Procesamiento principal
for schema in "${schemas[@]}"; do
  echo "Procesando esquema: $schema"
  
  # Consulta SQL
  execute_sql_origin "SELECT * FROM ${schema}.tabla;" "${schema}_tabla.csv"
  
  # Importar datos desde CSV a la base de datos destino
  import_csv_to_destination "${schema}_tabla.csv" "tabla_destino"

  
done

#Compresion XTF to ZIP

all_csv_files=(*.xtf)
compress_files "todos_los_archivos_csv.zip" "${all_csv_files[@]}"

echo "Proceso completado."
