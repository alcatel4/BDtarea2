
from flask import Blueprint, request, session, redirect, url_for
from conexionDB import get_connection

home_bp = Blueprint('home', __name__)

@home_bp.route('/home')
def home():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))
    
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

    if len(rows) == 0:
        filas_html = '<tr><td colspan="3">No se encontraron empleados</td></tr>'
    else:
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