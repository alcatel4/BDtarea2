# Punto de entrada de la aplicación Flask.
# Siguiendo una arquitectura en capas: presentación (HTML) -> lógica (Python) -> datos (SQL Server).

from flask import Flask
from login import login_bp
from home import home_bp
from logout import logout_bp
from empleados import empleados_bp
from mostrarMovimientos import movimientos_bp
from insertarMovimiento import insertar_movimiento_bp

app = Flask(__name__)
app.secret_key = 'clave_secreta'  # Necesaria para el manejo de sesiones de usuario (login/logout)

# Cada blueprint maneja una parte específica de la aplicación
app.register_blueprint(login_bp)
app.register_blueprint(home_bp)
app.register_blueprint(logout_bp)
app.register_blueprint(empleados_bp)
app.register_blueprint(movimientos_bp)
app.register_blueprint(insertar_movimiento_bp)

if __name__ == '__main__':
    app.run(debug=True)