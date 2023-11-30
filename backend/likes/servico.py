from flask import Flask, jsonify
import mysql.connector as mysql

servico = Flask(__name__)

# informacoes sobre o servico
DESCRICAO = "serviço que gerencia os likes/dislikes sobre um produto"
VERSAO = "0.0.1"
AUTOR = "luis paulo da silva carvalho"
EMAIL = "luispscarvalho@gmail.com"

MYSQL_SERVER = "bancodados"
MYSQL_USER = "root"
MYSQL_PASS = "admin"
MYSQL_DB = "marcas"

ALIVE = "yes"


@servico.route("/is_alive", methods=["GET"])
def is_alive():
    return jsonify(alive = ALIVE)


@servico.route("/info", methods=["GET"])
def get_info():
    return jsonify(
        descricao=DESCRICAO,
        versao=VERSAO,
        autor=AUTOR,
        email=EMAIL
    )


def get_conexao_bd():
    conexao = mysql.connect(
        host=MYSQL_SERVER, user=MYSQL_USER, password=MYSQL_PASS, database=MYSQL_DB
    )

    return conexao


@servico.route("/total_likes/<int:feed_id>", methods=["GET"])
def get_total_likes(feed_id):
    likes = 0

    conexao = get_conexao_bd()
    cursor = conexao.cursor(dictionary=True)
    cursor.execute(
        f"SELECT count(*) as total_likes FROM likes WHERE feed = {feed_id}")
    registro = cursor.fetchone()
    if registro:
        likes = registro["total_likes"]
    conexao.close()

    return str(likes)


@servico.route("/gostou/<string:conta>/<int:feed_id>", methods=["GET"])
def usuario_gostou(conta, feed_id):
    num_likes = 0

    conexao = get_conexao_bd()
    cursor = conexao.cursor(dictionary=True)
    cursor.execute("select count(*) as num_likes from likes " +
                   "where email = '" + conta + "' and feed = " + str(feed_id))
    registro = cursor.fetchone()
    if registro:
        num_likes = registro["num_likes"]

    return jsonify(likes=num_likes)


@servico.route("/gostar/<string:conta>/<int:feed_id>", methods=["POST"])
def gostar(conta, feed_id):
    resultado = {
        "situacao": "ok", 
        "erro": ""
    }

    conexao = get_conexao_bd()
    cursor = conexao.cursor()
    try:
        cursor.execute(
            f"INSERT INTO likes(feed, email) VALUES ({feed_id}, '{conta}')"
        )
        conexao.commit()
    except:
        conexao.rollback()

        resultado["situacao"] = "erro"
        resultado["erro"] = f"ocorreu um erro adicionando o like"

    conexao.close()

    return resultado


@servico.route("/desgostar/<string:conta>/<int:feed_id>", methods=["DELETE"])
def desgostar(conta, feed_id):
    resultado = {
        "situacao": "ok", 
        "erro": ""
    }

    conexao = get_conexao_bd()
    cursor = conexao.cursor()
    try:
        cursor.execute(
            f"DELETE FROM likes WHERE feed = {feed_id} AND email = '{conta}'"
        )
        conexao.commit()
    except:
        conexao.rollback()

        resultado["situacao"] = "erro"
        resultado["erro"] = f"ocorreu um erro removendo o like"

    conexao.close()

    return resultado


if __name__ == "__main__":
    servico.run(
        host="0.0.0.0",
        debug=True
    )
