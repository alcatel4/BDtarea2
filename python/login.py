from flask import Blueprint, request, session, redirect, url_for
from conexionDB import get_connection

login_bp = Blueprint('login', __name__)

@login_bp.route('/', methods=['GET'])
def index():
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

    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procLogin ?, ?, ?, @rc OUTPUT; SELECT @rc",
        username, password, ip
    )
    row = cursor.fetchone()
    code = row[0]

    conn.commit()
    cursor.close()
    conn.close()

    if code == 0:
        session['usuario'] = username
        return redirect(url_for('home.home'))
    else:
        conn2 = get_connection()
        cursor2 = conn2.cursor()
        cursor2.execute(
            "DECLARE @rc INT; EXEC dbo.procErroresLogin ?, @rc OUTPUT; SELECT @rc",
            code
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
        if code == 50003:
            html = html.replace(
                '<button type="submit">Ingresar</button>',
                '<button type="submit" disabled>Ingresar</button>'
            )
        return html