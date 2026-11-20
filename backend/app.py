import os

from flask import Flask

import favorites

app = Flask(__name__)
app.config["JSON_AS_ASCII"] = False
app.register_blueprint(favorites.bp)

if __name__ == "__main__":
    app.run(port=int(os.getenv("SERVER_PORT", 5001)), debug=True)
