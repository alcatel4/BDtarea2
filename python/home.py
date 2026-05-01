# Módulo principal (home) — R2: Listar empleados con filtro.

from flask import Blueprint, request, session, redirect, url_for
from conexionDB import get_connection

home_bp = Blueprint('home', __name__)

@home_bp.route('/home')
def home():
    if 'usuario' not in session:
        return redirect(url_for('login.login'))
    
    filtro = request.args.get('filtro', '') # Vacio = listar todos los empleados
    username = session['usuario']
    ip = request.remote_addr # IP para trazabilidad en la bitácora (R7)

    conn = get_connection()
    cursor = conn.cursor()

    # El SP devuelve si el filtro es por nombre (letras) o por cédula (números)
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
            # Los ids de empleado van en campos ocultos, nunca se muestran al usuario
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
                    <form action="/eliminar" method="POST" style="display:inline" id="form-eliminar-{row[0]}">
                        <input type="hidden" name="doc_id" value="{row[0]}" />
                        <input type="hidden" name="nombre_empleado" value="{row[1]}" />
                        <input type="hidden" name="confirmado" value="0" id="confirmado-{row[0]}" />
                        <button type="button" class="btn-accion btn-eliminar"
                            onclick="confirmarEliminar('{row[0]}', '{row[1]}')">Eliminar</button>
                    </form>
                    <form action="/movimientos" method="POST" style="display:inline">
                        <input type="hidden" name="doc_id" value="{row[0]}" />
                        <button class="btn-accion btn-movimientos">Movimientos</button>
                    </form>
                </td>
            </tr>'''

    with open('html/home.html', 'r', encoding='utf-8') as f:
        html = f.read()
    
    # Alerta de confirmación antes de ejecutar el borrado lógico (R4)
    # El campo de confirmado distingue si fue un intento de borrado o fue un borrado efectivo 
    script = """
    <script>
    function confirmarEliminar(docId, nombre) {
        var mensaje = 'Documento: ' + docId + '\\nNombre: ' + nombre + '\\n\\n¿Está seguro de eliminar este empleado?';
        if (confirm(mensaje)) {
            document.getElementById('confirmado-' + docId).value = '1';
        }
        document.getElementById('form-eliminar-' + docId).submit();
    }
    </script>
    """

    html = html.replace('<!--FILAS-->', filas_html)
    html = html.replace('</body>', script + '</body>')
    return html