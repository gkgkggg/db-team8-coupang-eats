import pymysql
from flask import Blueprint, jsonify, request

from common import error
from db import execute, query

bp = Blueprint("favorites", __name__)
DEFAULT_IMAGE_URL = (
    "https://raw.githubusercontent.com/gkgkggg/db-team8-coupang-eats/main/"
    "db/fixtures/common/no-photo.png"
)


@bp.route("/api/users/<int:user_id>/favorites", methods=["GET"])
def list_favorites(user_id):
    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)

    rows = query(
        """
        SELECT s.StoreID AS storeId,
               s.StoreName AS storeName,
               COALESCE(s.StoreImageURL, %s) AS storeImageUrl,
               s.MinimumOrderAmount AS minimumOrderAmount,
               s.DeliveryFee AS deliveryFee,
               s.EstimatedDeliveryMinutes AS estimatedDeliveryMinutes,
               s.IsOpen AS isOpen,
               f.CreatedAt AS favoritedAt
        FROM Favorites f
        JOIN Stores s ON f.StoreID = s.StoreID
        WHERE f.UserID = %s
        ORDER BY f.CreatedAt DESC
        """,
        (DEFAULT_IMAGE_URL, user_id),
    )
    for r in rows:
        r["isOpen"] = bool(r["isOpen"])

    return jsonify({"data": rows}), 200


@bp.route("/api/users/<int:user_id>/favorites", methods=["POST"])
def add_favorite(user_id):
    body = request.get_json(silent=True) or {}
    store_id = body.get("storeId")
    if not isinstance(store_id, int) or isinstance(store_id, bool):
        return error("INVALID_INPUT", "storeId는 정수여야 합니다.", 400)

    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)
    if not query("SELECT 1 FROM Stores WHERE StoreID = %s", (store_id,)):
        return error("STORE_NOT_FOUND", "가게를 찾을 수 없습니다.", 404)

    try:
        execute(
            "INSERT INTO Favorites (UserID, StoreID) VALUES (%s, %s)",
            (user_id, store_id),
        )
    except pymysql.err.IntegrityError:
        return error("ALREADY_FAVORITE", "이미 즐겨찾기한 가게입니다.", 409)

    return jsonify({"data": {"userId": user_id, "storeId": store_id}}), 201


@bp.route("/api/users/<int:user_id>/favorites/<int:store_id>", methods=["DELETE"])
def delete_favorite(user_id, store_id):
    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)

    deleted = execute(
        "DELETE FROM Favorites WHERE UserID = %s AND StoreID = %s",
        (user_id, store_id),
    )
    if deleted == 0:
        return error("FAVORITE_NOT_FOUND", "즐겨찾기에 없는 가게입니다.", 404)

    return "", 204
