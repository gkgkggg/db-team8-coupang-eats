import os
from datetime import datetime
from decimal import Decimal

import pymysql
from dotenv import load_dotenv

load_dotenv()


def get_conn():
    return pymysql.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", 3306)),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        db=os.getenv("DB_NAME", "db_team8"),
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
    )


def _clean(row):
    for k, v in row.items():
        if isinstance(v, Decimal):
            row[k] = int(v)
        elif isinstance(v, datetime):
            row[k] = v.isoformat(sep=" ")
    return row


def query(sql, params=()):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return [_clean(r) for r in cur.fetchall()]
    finally:
        conn.close()


def execute(sql, params=()):
    """INSERT/UPDATE/DELETE: 실행 후 커밋하고 영향받은 행 수를 반환"""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            n = cur.execute(sql, params)
        conn.commit()
        return n
    finally:
        conn.close()
