# Módulo de inserción de movimientos de vacaciones (R6).

from flask import Blueprint, request, session, redirect, url_for
from conexionDB import get_connection

insertar_movimiento_bp = Blueprint('insertar_movimiento', __name__)

@insertar_movimiento_bp.route('/insertar_movimiento', methods=['GET'])
def mostrar_form():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))

    doc_id = request.args.get('doc_id')
    username = session['usuario']

    # Se reutiliza procMostrarMovimientos para obtener doc, nombre y saldo actual del empleado
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procMostrarMovimientos ?, ?, @rc OUTPUT; SELECT @rc",
        doc_id, username
    )
    info = cursor.fetchone()
    cursor.close()
    conn.close()

    # Se cargan los tipos de movimiento para el dropdown (Crédito y Débito)
    conn2 = get_connection()
    cursor2 = conn2.cursor()
    cursor2.execute(
        "{CALL dbo.procListarTiposMovimiento(?)}", 0
    )
    tipos = cursor2.fetchall()
    cursor2.close()
    conn2.close()

    opciones_html = ''
    for tipo in tipos:
        opciones_html += f'<option value="{tipo[0]}">{tipo[0]}</option>'

    with open('html/insertar_movimiento.html', 'r', encoding='utf-8') as f:
        html = f.read()

    html = html.replace('<!--DOC_ID-->', str(info[0]))
    html = html.replace('<!--DOC_ID_VAL-->', str(info[0]))
    html = html.replace('<!--NOMBRE-->', str(info[1]))
    html = html.replace('<!--SALDO-->', str(info[2]))
    html = html.replace('<!--OPCIONES-->', opciones_html)
    html = html.replace('<!--ERROR-->', '')

    return html

@insertar_movimiento_bp.route('/insertar_movimiento', methods=['POST'])
def insertar():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))

    doc_id = request.form.get('doc_id')
    tipo_movimiento = request.form.get('tipo_movimiento')
    monto = request.form.get('monto')
    username = session['usuario']
    ip = request.remote_addr

    conn = get_connection()
    cursor = conn.cursor()

    # El SP valida que el monto no genere saldo negativo, actualiza SaldoVacaciones y se registra en la bitácora
    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procInsertarMovimiento ?, ?, ?, ?, ?, @rc OUTPUT; SELECT @rc",
        username, doc_id, tipo_movimiento, monto, ip
    )
    row = cursor.fetchone()
    result_code = row[0]
    conn.commit()
    cursor.close()
    conn.close()

    if result_code == 0:
        return redirect(f'/movimientos?doc_id={doc_id}')
    else:
        # Obtener descripcion del error
        conn2 = get_connection()
        cursor2 = conn2.cursor()
        cursor2.execute(
            "{CALL dbo.procErroresLogin(?, ?)}",
            result_code, 0
        )
        row2 = cursor2.fetchone()
        msg = row2[0] if row2 else 'Error desconocido'
        cursor2.close()
        conn2.close()

        # Se recargan los datos del empleado para mantener el contexto en pantalla
        conn3 = get_connection()
        cursor3 = conn3.cursor()
        cursor3.execute(
            "DECLARE @rc INT; EXEC dbo.procMostrarMovimientos ?, ?, @rc OUTPUT; SELECT @rc",
            doc_id, username
        )
        info = cursor3.fetchone()
        cursor3.close()
        conn3.close()

        # Tipos de movimiento
        conn4 = get_connection()
        cursor4 = conn4.cursor()
        cursor4.execute(
            "{CALL dbo.procListarTiposMovimiento(?)}", 0
        )
        tipos = cursor4.fetchall()
        cursor4.close()
        conn4.close()

        opciones_html = ''
        for tipo in tipos:
            opciones_html += f'<option value="{tipo[0]}">{tipo[0]}</option>'

        with open('html/insertar_movimiento.html', 'r', encoding='utf-8') as f:
            html = f.read()

        html = html.replace('<!--DOC_ID-->', str(info[0]))
        html = html.replace('<!--DOC_ID_VAL-->', str(info[0]))
        html = html.replace('<!--NOMBRE-->', str(info[1]))
        html = html.replace('<!--SALDO-->', str(info[2]))
        html = html.replace('<!--OPCIONES-->', opciones_html)
        html = html.replace('<!--ERROR-->', msg)

        return html