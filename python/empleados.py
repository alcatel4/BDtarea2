from flask import Blueprint, request, session, redirect, url_for
from conexionDB import get_connection

empleados_bp = Blueprint('empleados', __name__)


@empleados_bp.route('/empleados/insertar', methods=['GET'])
def mostrar_insertar_empleado():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))

    conn   = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT Id, Nombre FROM dbo.Puesto ORDER BY Nombre ASC")
    puestos = cursor.fetchall()

    cursor.close()
    conn.close()

    opciones = ''
    for puesto in puestos:
        opciones += f'<option value="{puesto[0]}">{puesto[1]}</option>'

    with open('html/insertar_empleado.html', 'r', encoding='utf-8') as f:
        html = f.read()

    html = html.replace('<!--PUESTOS-->', opciones)
    html = html.replace('<!--ERROR-->', '')
    return html


@empleados_bp.route('/empleados/insertar', methods=['POST'])
def do_insertar_empleado():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))

    documento = request.form.get('documento')
    nombre    = request.form.get('nombre')
    id_puesto = request.form.get('id_puesto')
    username  = session['usuario']
    ip        = request.remote_addr

    conn   = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procInsertarEmpleado ?, ?, ?, ?, ?, @rc OUTPUT; SELECT @rc",
        documento, nombre, id_puesto, username, ip
    )
    row  = cursor.fetchone()
    code = row[0]

    conn.commit()
    cursor.close()
    conn.close()

    if code == 0:
        return redirect(url_for('home.home'))

    # Si hubo error, obtener descripción
    conn2   = get_connection()
    cursor2 = conn2.cursor()

    cursor2.execute(
        "DECLARE @rc INT; EXEC dbo.procDescErrores ?, @rc OUTPUT; SELECT @rc",
        code
    )
    row2 = cursor2.fetchone()
    msg  = row2[0]

    cursor2.close()
    conn2.close()

    # Recargar puestos para el dropdown
    conn3   = get_connection()
    cursor3 = conn3.cursor()

    cursor3.execute("SELECT Id, Nombre FROM dbo.Puesto ORDER BY Nombre ASC")
    puestos = cursor3.fetchall()

    cursor3.close()
    conn3.close()

    opciones = ''
    for puesto in puestos:
        opciones += f'<option value="{puesto[0]}">{puesto[1]}</option>'

    with open('html/insertar_empleado.html', 'r', encoding='utf-8') as f:
        html = f.read()

    html = html.replace('<!--PUESTOS-->', opciones)
    html = html.replace('<!--ERROR-->', msg)
    return html