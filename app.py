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
    with open('html/login.html', 'r', encoding='utf-8') as f:
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
    
@app.route('/home')
def home():
    if 'usuario' not in session:
        return redirect(url_for('login'))
    
    filtro = request.args.get('filtro', '')
    username = session['usuario']
    ip = request.remote_addr

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procMostrarEmpleados ?, ?, ?, @rc OUTPUT; SELECT @rc",
        filtro, username, ip
    )
    
    rows = cursor.fetchall()
    conn.commit()
    cursor.close()
    conn.close()

    filas_html = ''
    for row in rows:
        filas_html += f'''
        <tr>
            <td>{row[0]}</td>
            <td>{row[1]}</td>
            <td>
                <form action="/consultar" method="POST" style="display:inline">
                    <input type="hidden" name="doc_id" value="{row[0]}" />
                    <button class="btn-accion btn-consultar">Consultar</button>
                </form>
                <form action="/editar" method="GET" style="display:inline">
                    <input type="hidden" name="doc_id" value="{row[0]}" />
                    <button class="btn-accion btn-editar">Editar</button>
                </form>
                <form action="/eliminar" method="POST" style="display:inline">
                    <input type="hidden" name="doc_id" value="{row[0]}" />
                    <button class="btn-accion btn-eliminar">Eliminar</button>
                </form>
                <form action="/movimientos" method="POST" style="display:inline">
                    <input type="hidden" name="doc_id" value="{row[0]}" />
                    <button class="btn-accion btn-movimientos">Movimientos</button>
                </form>
            </td>
        </tr>'''

    with open('html/home.html', 'r', encoding='utf-8') as f:
        html = f.read()
    
    html = html.replace('<!--FILAS-->', filas_html)
    return html

@app.route('/logout', methods=['POST'])
def logout():
    session.pop('usuario', None)
    return redirect(url_for('login'))
if __name__ == '__main__':
    app.run(debug=True)