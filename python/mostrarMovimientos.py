# Módulo de listado de movimientos de vacaciones (R5).

from flask import Blueprint, request, session, redirect, url_for
from conexionDB import get_connection

movimientos_bp = Blueprint('movimientos', __name__)

@movimientos_bp.route('/movimientos',methods=['GET', 'POST'])
def movimientos():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))

    # Acepta doc_id tanto por GET (desde insertarMovimiento) como por POST (desde home)
    doc_id = request.form.get('doc_id') or request.args.get('doc_id')
    username = session['usuario']

    conn = get_connection()
    cursor = conn.cursor()

    # El SP retorna dos resultsets: info del empleado y sus movimientos
    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procMostrarMovimientos ?, ?, @rc OUTPUT; SELECT @rc",
        doc_id, username
    )

    # Primer SELECT — info del empleado
    info = cursor.fetchone()

    # Segundo SELECT — movimientos
    cursor.nextset()
    movimientos = cursor.fetchall()

    conn.commit()
    cursor.close()
    conn.close()

    # Construir filas
    filas_html = ''
    if len(movimientos) == 0:
        filas_html = '<tr><td colspan="7">No hay movimientos</td></tr>'
    else:
        # Columnas: fecha, tipo, monto, nuevo saldo, usuario, IP, estampa de tiempo (R5)
        for mov in movimientos:
            filas_html += f'''
            <tr>
                <td>{mov[0]}</td>
                <td>{mov[1]}</td>
                <td>{mov[2]}</td>
                <td>{mov[3]}</td>
                <td>{mov[4]}</td>
                <td>{mov[5]}</td>
                <td>{mov[6]}</td>
            </tr>'''

    with open('html/mostrar_movimientos.html', 'r', encoding='utf-8') as f:
        html = f.read()

    html = html.replace('<!--DOC_ID-->', str(info[0]))
    html = html.replace('<!--DOC_ID_VAL-->', str(info[0]))
    html = html.replace('<!--NOMBRE-->', str(info[1]))
    html = html.replace('<!--SALDO-->', str(info[2]))
    html = html.replace('<!--FILAS-->', filas_html)

    return html