from flask import jsonify


def error(code, message, status):
    return jsonify({"error": {"code": code, "message": message}}), status
