from flask import Flask, jsonify
import mysql.connector as mysql

servico = Flask(__name__)

# informacoes sobre o servico
DESCRICAO = "serviço que gerencia os comentarios sobre um produto"
VERSAO = "0.0.1"
AUTOR = "luis paulo da silva carvalho"
EMAIL = "luispscarvalho@gmail.com"

MYSQL_SERVER = "bancodados"
MYSQL_USER = "root"
MYSQL_PASS = "admin"
MYSQL_DB = "marcas"

ALIVE = "yes"

def gerar_comentario(registro):
    comentario = {
        "_id": registro["id"],
        "feed": registro["feed"],
        "user": {
            "account": registro["conta"],
            "name": registro["nome"]
        },
        "datetime": registro["data"],
        "content": registro["comentario"]
    }

    return comentario


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


@servico.route("/comentarios/<int:feed_id>/<int:pagina>/<int:tamanho_pagina>",
               methods=["GET"])
def get_comentarios(feed_id, pagina, tamanho_pagina):
    comentarios = []

    conexao = get_conexao_bd()
    cursor = conexao.cursor(dictionary=True)
    cursor.execute("SELECT id, feed, comentario, nome, conta, DATE_FORMAT(data, '%Y-%m-%d %H:%i') as data " +
                   "FROM comentarios " +
                   "WHERE feed = " + str(feed_id) + " ORDER BY data DESC " +
                   "LIMIT " + str((pagina - 1) * tamanho_pagina) + ", " + str(tamanho_pagina))
    registros = cursor.fetchall()
    conexao.close()

    for registro in registros:
        comentarios.append(gerar_comentario(registro))

    return jsonify(comentarios)


@servico.route("/adicionar/<int:feed_id>/<string:nome>/<string:conta>/<string:comentario>", methods=["POST"])
def add_comentario(feed_id, nome, conta, comentario):
    resultado = {
        "situacao": "ok",
        "erro": ""
    }

    conexao = get_conexao_bd()
    cursor = conexao.cursor()
    try:
        cursor.execute(
            f"INSERT INTO comentarios(feed, nome, conta, comentario, data) VALUES({feed_id}, '{nome}', '{conta}', '{comentario}', NOW())")
        conexao.commit()
    except Exception as e:
        conexao.rollback()

        resultado["situacao"] = "erro"
        resultado["erro"] = f"ocorreu um erro adicionando um comentário"

    conexao.close()

    return jsonify(resultado)

@servico.route("/remover/<int:comentario_id>", methods=["DELETE"])
def remover_comentario(comentario_id):
    resultado = {
        "situacao": "ok",
        "erro": ""
    }

    conexao = get_conexao_bd()
    cursor = conexao.cursor()
    try:
        cursor.execute(
            f"DELETE FROM comentarios WHERE id = {comentario_id}")
        conexao.commit()
    except Exception as e:
        conexao.rollback()

        resultado["situacao"] = "erro"
        resultado["erro"] = f"ocorreu um erro removendo o comentário"

    conexao.close()

    return jsonify(resultado)


if __name__ == "__main__":
    servico.run(
        host="0.0.0.0",
        debug=True
    )
