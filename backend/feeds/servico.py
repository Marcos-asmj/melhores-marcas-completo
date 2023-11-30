from flask import Flask, jsonify
import mysql.connector as mysql
import urllib.request

servico = Flask(__name__)

# informacoes sobre o servico
DESCRICAO = "serviço que gerencia os feeds de produto"
VERSAO = "0.0.1"
AUTOR = "luis paulo da silva carvalho"
EMAIL = "luispscarvalho@gmail.com"

URL_TOTAL_DE_LIKES = "http://likes:5000/total_likes/"

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

def acessar(url):
    resposta = urllib.request.urlopen(url)
    dados = resposta.read()

    return dados.decode("utf-8")

# idealmente, o servico de likes deveria ser consultado
def get_total_likes(feed_id):
    total = acessar(URL_TOTAL_DE_LIKES + str(feed_id))

    return int(total)


def gerar_feed(registro):
    feed = {
        "_id": registro["feed_id"],
        "datetime": registro["data"],
        "company": {
            "_id": registro["empresa_id"],
            "name": registro["nome_empresa"],
            "avatar": registro["avatar"]
        },
        "likes": registro["likes"],
        "product": {
            "name": registro["nome_produto"],
            "description": registro["descricao"],
            "price": registro["preco"],
            "url": registro["url"],
            "blobs": [
                {
                    "type": "image",
                    "file": registro["imagem1"]
                },
                {
                    "type": "image",
                    "file": registro["imagem2"]
                },
                {
                    "type": "image",
                    "file": registro["imagem3"]
                }
            ]
        }
    }

    return feed


@servico.route("/feeds/<int:pagina>/<int:tamanho_pagina>")
def get_feeds(pagina, tamanho_pagina):
    feeds = []

    conexao = get_conexao_bd()
    cursor = conexao.cursor(dictionary=True)
    cursor.execute(
        "SELECT feeds.id as feed_id, DATE_FORMAT(feeds.data, '%Y-%m-%d %H:%i') " +
        "as data, empresas.id as empresa_id, empresas.nome as nome_empresa, " +
        "empresas.avatar, produtos.nome as nome_produto, produtos.descricao, " +
        "FORMAT(produtos.preco, 2) as preco, produtos.url, produtos.imagem1, " +
        "IFNULL(produtos.imagem2, '') as imagem2, " +
        "IFNULL(produtos.imagem3, '') as imagem3 " +
        "FROM feeds, empresas, produtos " +
        "WHERE produtos.id = feeds.id " +
        "AND empresas.id = produtos.empresa " +
        "ORDER BY data desc " +
        "LIMIT " + str((pagina - 1) * tamanho_pagina) +
        ", " + str(tamanho_pagina)
    )
    registros = cursor.fetchall()
    conexao.close()

    for registro in registros:
        registro["likes"] = get_total_likes(registro["feed_id"])
        feeds.append(gerar_feed(registro))
 
    return jsonify(feeds)


@servico.route("/feed/<int:feed_id>")
def get_feed(feed_id):
    feed = {}

    conexao = get_conexao_bd()
    cursor = conexao.cursor(dictionary=True)
    cursor.execute(
        "SELECT feeds.id as feed_id, DATE_FORMAT(feeds.data, '%Y-%m-%d %H:%i') " +
        "as data, empresas.id as empresa_id, empresas.nome as nome_empresa, " +
        "empresas.avatar, produtos.nome as nome_produto, produtos.descricao, " +
        "FORMAT(produtos.preco, 2) as preco, produtos.url, produtos.imagem1, " +
        "IFNULL(produtos.imagem2, '') as imagem2, " +
        "IFNULL(produtos.imagem3, '') as imagem3 " +
        "FROM feeds, empresas, produtos " +
        "WHERE produtos.id = feeds.id " +
        "AND empresas.id = produtos.empresa " +
        "AND feeds.id = " + str(feed_id)
    )
    registro = cursor.fetchone()
    conexao.close()

    if registro:
        registro["likes"] = get_total_likes(registro["feed_id"])
        feed = gerar_feed(registro)
 
    return jsonify(feed)


if __name__ == "__main__":
    servico.run(
        host="0.0.0.0",
        debug=True
    )
