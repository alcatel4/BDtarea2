import pyodbc
from flask import Flask, request, session, redirect, url_for

app = Flask(__name__)
app.secret_key = 'clave_secreta'

def get_connection():
    return pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=tcp:sqlserver-tarea1.database.windows.net;'
        'DATABASE=bd_tarea2;'
        'UID=Tarea1;'
        'PWD=@2026SQL;'
        'Encrypt=yes;'
        'TrustServerCertificate=no;'
    )

@app.route('/', methods=['GET'])
def index():
    return redirect(url_for('login'))

@app.route('/login', methods=['GET'])
def login():
    with open('login.html', 'r', encoding='utf-8') as f:
        html = f.read()
    return html

@app.route('/login', methods=['POST'])
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
        return redirect(url_for('home'))
    else:
        conn2 = get_connection()
        cursor2 = conn2.cursor()
        cursor2.execute(
            "DECLARE @rc INT; EXEC dbo.procErroresLogin ?, @rc OUTPUT; SELECT @rc",
            code
        )
        row2 = cursor2.fetchone()
        msg = row2[0]
        cursor2.close()
        conn2.close()

        with open('login.html', 'r', encoding='utf-8') as f:
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
    
@app.route('/home')
def home():
    if 'usuario' not in session:
        return redirect(url_for('login'))
    with open('home.html', 'r', encoding='utf-8') as f:
        html = f.read()
    return html
if __name__ == '__main__':
    app.run(debug=True)