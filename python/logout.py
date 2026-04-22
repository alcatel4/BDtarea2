from flask import Blueprint, request, session, redirect, url_for
from conexionDB import get_connection

logout_bp = Blueprint('logout', __name__)

@logout_bp.route('/logout', methods=['POST'])
def logout():
    username = session.get('usuario', '')
    ip = request.remote_addr

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "DECLARE @rc INT; EXEC dbo.procLogout ?, ?, @rc OUTPUT; SELECT @rc",
        username, ip
    )

    conn.commit()
    cursor.close()
    conn.close()

    session.pop('usuario', None)
    return redirect(url_for('login.login'))