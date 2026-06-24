import pymysql
from pymysql.cursors import DictCursor

import config


def get_connection():
    return pymysql.connect(
        host=config.MYSQL_HOST,
        port=config.MYSQL_PORT,
        user=config.MYSQL_USER,
        password=config.MYSQL_PASSWORD,
        database=config.MYSQL_DATABASE,
        charset=config.MYSQL_CHARSET,
        cursorclass=DictCursor,
        autocommit=True,
    )


def query_all(sql, args=None):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, args or ())
            return cur.fetchall()
    finally:
        conn.close()


def query_one(sql, args=None):
    rows = query_all(sql, args)
    return rows[0] if rows else None


def execute(sql, args=None):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, args or ())
            if cur.lastrowid:
                return cur.lastrowid
            return cur.rowcount
    finally:
        conn.close()
