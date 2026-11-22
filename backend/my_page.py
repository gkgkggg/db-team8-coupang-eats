from flask import Blueprint, jsonify, request

from common import error
from db import execute, insert, query, run_transaction

bp = Blueprint("my_page", __name__)


def mask_phone(phone):
    """010-1111-1234 -> 010-****-1234"""
    if not phone:
        return None
    parts = phone.split("-")
    if len(parts) == 3:
        return f"{parts[0]}-****-{parts[2]}"
    return phone[:3] + "****" + phone[-4:]


@bp.route("/api/users/<int:user_id>", methods=["GET"])
def get_user(user_id):
    rows = query(
        "SELECT UserID, UserName, UserPhone FROM Users WHERE UserID = %s",
        (user_id,),
    )
    if not rows:
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)

    u = rows[0]
    return jsonify({"data": {
        "userId": u["UserID"],
        "userName": u["UserName"],
        "userPhone": mask_phone(u["UserPhone"]),
    }}), 200


@bp.route("/api/users/<int:user_id>/summary", methods=["GET"])
def get_summary(user_id):
    rows = query(
        """
        SELECT u.UserID, u.UserName, u.UserPhone,
               (SELECT COUNT(*)
                  FROM Reviews r
                  JOIN Orders o ON r.OrderID = o.OrderID
                 WHERE o.UserID = u.UserID) AS reviewCount,
               (SELECT COUNT(*)
                  FROM ReviewHelpful h
                  JOIN Reviews r ON h.ReviewID = r.ReviewID
                  JOIN Orders o ON r.OrderID = o.OrderID
                 WHERE o.UserID = u.UserID AND h.IsHelpful = TRUE) AS helpfulCount,
               (SELECT COUNT(*)
                  FROM Favorites f
                 WHERE f.UserID = u.UserID) AS favoriteCount
        FROM Users u
        WHERE u.UserID = %s
        """,
        (user_id,),
    )
    if not rows:
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)

    s = rows[0]
    return jsonify({"data": {
        "userId": s["UserID"],
        "userName": s["UserName"],
        "userPhone": mask_phone(s["UserPhone"]),
        "reviewCount": s["reviewCount"],
        "helpfulCount": s["helpfulCount"],
        "favoriteCount": s["favoriteCount"],
    }}), 200


@bp.route("/api/users/<int:user_id>/reviews", methods=["GET"])
def list_my_reviews(user_id):
    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)

    rows = query(
        """
        SELECT r.ReviewID AS reviewId,
               r.OrderID AS orderId,
               s.StoreID AS storeId,
               s.StoreName AS storeName,
               r.Rating AS rating,
               r.Content AS content,
               r.CreatedAt AS createdAt,
               (SELECT COUNT(*) FROM ReviewHelpful h
                 WHERE h.ReviewID = r.ReviewID AND h.IsHelpful = TRUE) AS helpfulCount,
               (SELECT COUNT(*) FROM ReviewHelpful h
                 WHERE h.ReviewID = r.ReviewID AND h.IsHelpful = FALSE) AS notHelpfulCount,
               (SELECT h.IsHelpful FROM ReviewHelpful h
                 WHERE h.ReviewID = r.ReviewID AND h.UserID = %s) AS myReaction
        FROM Reviews r
        JOIN Orders o ON r.OrderID = o.OrderID
        JOIN Stores s ON o.StoreID = s.StoreID
        WHERE o.UserID = %s
        ORDER BY r.CreatedAt DESC
        """,
        (user_id, user_id),
    )
    for r in rows:
        if r["myReaction"] is not None:
            r["myReaction"] = bool(r["myReaction"])

    return jsonify({"data": rows}), 200


@bp.route("/api/users/<int:user_id>/helpful-reviews/<int:review_id>", methods=["PUT"])
def put_helpful(user_id, review_id):
    body = request.get_json(silent=True) or {}
    is_helpful = body.get("isHelpful")
    if not isinstance(is_helpful, bool):
        return error("INVALID_INPUT", "isHelpful은 true 또는 false여야 합니다.", 400)

    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)
    if not query("SELECT 1 FROM Reviews WHERE ReviewID = %s", (review_id,)):
        return error("REVIEW_NOT_FOUND", "리뷰를 찾을 수 없습니다.", 404)

    execute(
        """
        INSERT INTO ReviewHelpful (UserID, ReviewID, IsHelpful)
        VALUES (%s, %s, %s) AS new
        ON DUPLICATE KEY UPDATE IsHelpful = new.IsHelpful
        """,
        (user_id, review_id, is_helpful),
    )
    return jsonify({"data": {
        "userId": user_id,
        "reviewId": review_id,
        "isHelpful": is_helpful,
    }}), 200


@bp.route("/api/users/<int:user_id>/helpful-reviews/<int:review_id>", methods=["DELETE"])
def delete_helpful(user_id, review_id):
    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)

    deleted = execute(
        "DELETE FROM ReviewHelpful WHERE UserID = %s AND ReviewID = %s",
        (user_id, review_id),
    )
    if deleted == 0:
        return error("REACTION_NOT_FOUND", "취소할 반응이 없습니다.", 404)

    return "", 204


@bp.route("/api/users/<int:user_id>/addresses", methods=["GET"])
def list_addresses(user_id):
    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)

    rows = query(
        """
        SELECT AddressID AS addressId,
               AddressLabel AS addressLabel,
               PostalCode AS postalCode,
               AddressLine1 AS addressLine1,
               AddressLine2 AS addressLine2,
               IsDefault AS isDefault,
               CreatedAt AS createdAt
        FROM Addresses
        WHERE UserID = %s
        ORDER BY IsDefault DESC, CreatedAt ASC
        """,
        (user_id,),
    )
    for r in rows:
        r["isDefault"] = bool(r["isDefault"])

    return jsonify({"data": rows}), 200


def parse_address(body):
    """주소 입력 검증. 성공: ((label, postal, line1, line2), None), 실패: (None, 메시지)"""
    label = body.get("addressLabel")
    postal = body.get("postalCode")
    line1 = body.get("addressLine1")
    line2 = body.get("addressLine2")

    if not isinstance(label, str) or not label.strip() or len(label) > 20:
        return None, "addressLabel은 1~20자 문자열이어야 합니다."
    if postal is not None and not (
        isinstance(postal, str) and len(postal) == 5 and postal.isdigit()
    ):
        return None, "postalCode는 숫자 5자리 문자열이거나 null이어야 합니다."
    if not isinstance(line1, str) or not line1.strip() or len(line1) > 200:
        return None, "addressLine1은 1~200자 문자열이어야 합니다."
    if line2 is not None and (not isinstance(line2, str) or len(line2) > 100):
        return None, "addressLine2는 100자 이하 문자열이거나 null이어야 합니다."

    return (label.strip(), postal, line1.strip(), line2), None


@bp.route("/api/users/<int:user_id>/addresses", methods=["POST"])
def add_address(user_id):
    body = request.get_json(silent=True) or {}
    values, msg = parse_address(body)
    if msg:
        return error("INVALID_INPUT", msg, 400)

    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)

    count = query(
        "SELECT COUNT(*) AS c FROM Addresses WHERE UserID = %s", (user_id,)
    )[0]["c"]
    is_default = (count == 0)  # 첫 주소는 자동으로 기본 주소

    label, postal, line1, line2 = values
    address_id = insert(
        """
        INSERT INTO Addresses
            (UserID, AddressLabel, PostalCode, AddressLine1, AddressLine2, IsDefault)
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        (user_id, label, postal, line1, line2, is_default),
    )
    return jsonify({"data": {
        "addressId": address_id,
        "addressLabel": label,
        "postalCode": postal,
        "addressLine1": line1,
        "addressLine2": line2,
        "isDefault": is_default,
    }}), 201


@bp.route("/api/users/<int:user_id>/addresses/<int:address_id>", methods=["PUT"])
def update_address(user_id, address_id):
    body = request.get_json(silent=True) or {}
    values, msg = parse_address(body)
    if msg:
        return error("INVALID_INPUT", msg, 400)

    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)
    if not query(
        "SELECT 1 FROM Addresses WHERE AddressID = %s AND UserID = %s",
        (address_id, user_id),
    ):
        return error("ADDRESS_NOT_FOUND", "주소를 찾을 수 없습니다.", 404)

    label, postal, line1, line2 = values
    execute(
        """
        UPDATE Addresses
           SET AddressLabel = %s, PostalCode = %s,
               AddressLine1 = %s, AddressLine2 = %s
         WHERE AddressID = %s AND UserID = %s
        """,
        (label, postal, line1, line2, address_id, user_id),
    )

    row = query(
        """
        SELECT AddressID AS addressId, AddressLabel AS addressLabel,
               PostalCode AS postalCode, AddressLine1 AS addressLine1,
               AddressLine2 AS addressLine2, IsDefault AS isDefault,
               CreatedAt AS createdAt
        FROM Addresses WHERE AddressID = %s
        """,
        (address_id,),
    )[0]
    row["isDefault"] = bool(row["isDefault"])
    return jsonify({"data": row}), 200


@bp.route("/api/users/<int:user_id>/addresses/<int:address_id>", methods=["DELETE"])
def delete_address(user_id, address_id):
    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)

    deleted = execute(
        "DELETE FROM Addresses WHERE AddressID = %s AND UserID = %s",
        (address_id, user_id),
    )
    if deleted == 0:
        return error("ADDRESS_NOT_FOUND", "주소를 찾을 수 없습니다.", 404)

    return "", 204


@bp.route("/api/users/<int:user_id>/default-address", methods=["PUT"])
def set_default_address(user_id):
    body = request.get_json(silent=True) or {}
    address_id = body.get("addressId")
    if not isinstance(address_id, int) or isinstance(address_id, bool):
        return error("INVALID_INPUT", "addressId는 정수여야 합니다.", 400)

    if not query("SELECT 1 FROM Users WHERE UserID = %s", (user_id,)):
        return error("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", 404)
    if not query(
        "SELECT 1 FROM Addresses WHERE AddressID = %s AND UserID = %s",
        (address_id, user_id),
    ):
        return error("ADDRESS_NOT_FOUND", "주소를 찾을 수 없습니다.", 404)

    run_transaction([
        # 1) 기존 기본 주소 해제 (먼저!)
        ("UPDATE Addresses SET IsDefault = FALSE WHERE UserID = %s AND IsDefault = TRUE",
         (user_id,)),
        # 2) 새 기본 주소 지정
        ("UPDATE Addresses SET IsDefault = TRUE WHERE AddressID = %s AND UserID = %s",
         (address_id, user_id)),
    ])
    return jsonify({"data": {
        "userId": user_id,
        "addressId": address_id,
        "isDefault": True,
    }}), 200
