import pyodbc
#Conexión a la base de datos
try:
    connection=pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=tcp:sqlserver-tarea1.database.windows.net;DATABASE=bd_tarea2;UID=Tarea1;PWD=@2026SQL;Encrypt=yes;TrustServerCertificate=no;')
    print("conexion exitosa")
except Exception as ex:
    print(ex)
