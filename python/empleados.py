from flask import Blueprint, request, session, redirect, url_for
from conexionDB import get_connection

empleados_bp = Blueprint('empleados', __name__)


# ─── R3: Insertar Empleado ────────────────────────────────────────────────────

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


# ─── R4: Consultar Empleado ───────────────────────────────────────────────────

@empleados_bp.route('/consultar', methods=['POST'])
def consultar_empleado():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))

    doc_id   = request.form.get('doc_id')
    username = session['usuario']
    ip       = request.remote_addr

    conn   = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procConsultarEmpleado ?, ?, @rc OUTPUT; SELECT @rc",
        username, doc_id
    )
    row  = cursor.fetchone()
    code = cursor.fetchone()[0] if row is None else None

    # Si el primer fetchone trajo datos del empleado
    if row is not None:
        doc      = row[0]
        nombre   = row[1]
        puesto   = row[2]
        saldo    = row[3]
        cursor.nextset()
        code = cursor.fetchone()[0]

    conn.commit()
    cursor.close()
    conn.close()

    with open('html/consultar_empleado.html', 'r', encoding='utf-8') as f:
        html = f.read()

    html = html.replace('<!--DOC_ID-->', str(doc))
    html = html.replace('<!--NOMBRE-->', str(nombre))
    html = html.replace('<!--PUESTO-->', str(puesto))
    html = html.replace('<!--SALDO-->', str(saldo))
    return html


# ─── R4: Editar Empleado (mostrar formulario) ─────────────────────────────────

@empleados_bp.route('/editar', methods=['GET'])
def mostrar_editar_empleado():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))

    doc_id   = request.args.get('doc_id')
    username = session['usuario']
    ip       = request.remote_addr

    # Traer datos actuales del empleado
    conn   = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procConsultarEmpleado ?, ?, @rc OUTPUT; SELECT @rc",
        username, doc_id
    )
    row = cursor.fetchone()

    nombre = ''
    if row is not None:
        nombre = row[1]

    # Traer puestos para el dropdown
    cursor.execute("SELECT Id, Nombre FROM dbo.Puesto ORDER BY Nombre ASC")
    puestos = cursor.fetchall()

    cursor.close()
    conn.close()

    opciones = ''
    for puesto in puestos:
        opciones += f'<option value="{puesto[0]}">{puesto[1]}</option>'

    with open('html/editar_empleado.html', 'r', encoding='utf-8') as f:
        html = f.read()

    html = html.replace('<!--DOC_ID-->', str(doc_id))
    html = html.replace('<!--NOMBRE-->', str(nombre))
    html = html.replace('<!--PUESTOS-->', opciones)
    html = html.replace('<!--ERROR-->', '')
    return html


# ─── R4: Editar Empleado (guardar cambios) ────────────────────────────────────

@empleados_bp.route('/empleados/editar', methods=['POST'])
def do_editar_empleado():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))

    doc_id_anterior = request.form.get('doc_id_anterior')
    doc_id_nuevo    = request.form.get('documento')
    nombre          = request.form.get('nombre')
    id_puesto       = request.form.get('id_puesto')
    username        = session['usuario']
    ip              = request.remote_addr

    conn   = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procActualizarEmpleado ?, ?, ?, ?, ?, ?, @rc OUTPUT; SELECT @rc",
        doc_id_anterior, doc_id_nuevo, nombre, id_puesto, username, ip
    )
    cursor.nextset()
    code = cursor.fetchone()[0]

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
    msg  = row2[0] if row2 else 'Error desconocido'

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

    with open('html/editar_empleado.html', 'r', encoding='utf-8') as f:
        html = f.read()

    html = html.replace('<!--DOC_ID-->', str(doc_id_anterior))
    html = html.replace('<!--NOMBRE-->', str(nombre))
    html = html.replace('<!--PUESTOS-->', opciones)
    html = html.replace('<!--ERROR-->', msg)
    return html


# ─── R4: Eliminar Empleado ────────────────────────────────────────────────────

@empleados_bp.route('/eliminar', methods=['POST'])
def eliminar_empleado():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))

    doc_id      = request.form.get('doc_id')
    confirmado  = request.form.get('confirmado', '0')
    username    = session['usuario']
    ip          = request.remote_addr

    conn   = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procEliminarEmpleado ?, ?, ?, ?, @rc OUTPUT; SELECT @rc",
        username, ip, doc_id, confirmado
    )
    cursor.nextset()
    code = cursor.fetchone()[0]

    conn.commit()
    cursor.close()
    conn.close()

    return redirect(url_for('home.home'))