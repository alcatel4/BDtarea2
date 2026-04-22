from flask import Flask
from login import login_bp
from home import home_bp
from logout import logout_bp

app = Flask(__name__)
app.secret_key = 'clave_secreta'

app.register_blueprint(login_bp)
app.register_blueprint(home_bp)
app.register_blueprint(logout_bp)

if __name__ == '__main__':
    app.run(debug=True)

