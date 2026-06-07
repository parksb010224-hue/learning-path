import pymysql

def get_connection():
    return pymysql.connect(
        host="127.0.0.1",
        user="root",
        password="aaaa",
        database="problem_list",
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor
    )