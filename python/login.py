# Módulo de autenticación (R1: Login).

from flask import Blueprint, request, session, redirect, url_for
from conexionDB import get_connection

login_bp = Blueprint('login', __name__)

@login_bp.route('/', methods=['GET'])
def index():
     # La raíz de la aplicación redirige siempre al login
    return redirect(url_for('login.login'))

@login_bp.route('/login', methods=['GET'])
def login():
    with open('html/login.html', 'r', encoding='utf-8') as f:
        html = f.read()
    return html

@login_bp.route('/login', methods=['POST'])
def do_login():
    username = request.form.get('usuario')
    password = request.form.get('password')
    ip = request.remote_addr

    conn = get_connection()
    cursor = conn.cursor()

    # El SP valida credenciales, cuenta intentos fallidos en los últimos 20 minutos y lo registra en la bitácora (R7)
    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procLogin ?, ?, ?, @rc OUTPUT; SELECT @rc",
        username, password, ip # IP para trazabilidad en bitácora (R7)
    )
    row = cursor.fetchone()
    code = row[0]

    conn.commit()
    cursor.close()
    conn.close()

    if code == 0:
        # Login exitoso: se inicia sesión con el username para usarlo en trazabilidad
        session['usuario'] = username
        return redirect(url_for('home.home'))
    else:
        # Login fallido: se consulta la descripción del error en el catálogo (R8)
        conn2 = get_connection()
        cursor2 = conn2.cursor()
        cursor2.execute(
            "{CALL dbo.procErroresLogin(?, ?)}",
            code, 0
        )
        row2 = cursor2.fetchone()
        msg = row2[0] if row2 else 'Error desconocido'
        cursor2.close()
        conn2.close()

        with open('html/login.html', 'r', encoding='utf-8') as f:
            html = f.read()
        html = html.replace(
            '<p class="error" id="error"></p>',
            f'<p class="error" id="error">{msg}</p>'
        )
        # Código 50003: login deshabilitado por exceso de intentos — se bloquea el botón (R1)
        if code == 50003:
            html = html.replace(
                '<button type="submit">Ingresar</button>',
                '<button type="submit" disabled>Ingresar</button>'
            )
        return html