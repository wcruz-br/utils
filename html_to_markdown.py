# -*- coding: utf-8 -*-

import html2text
import sys
import os

def html_para_markdown(html: str) -> str:
    """
    Converte uma string HTML para Markdown.
    """
    conversor = html2text.HTML2Text()
    conversor.single_line_break = True
    conversor.ignore_links = False
    conversor.ignore_images = False
    conversor.body_width = 0
    return conversor.handle(html)

def converter_arquivo_html(arquivo_html: str, arquivo_md: str):
    """
    Lê um arquivo HTML e escreve o conteúdo convertido em Markdown em outro arquivo.
    """
    with open(arquivo_html, 'r', encoding='utf-8') as f:
        html = f.read()
    markdown = html_para_markdown(html)
    with open(arquivo_md, 'w', encoding='utf-8') as f:
        f.write(markdown)
    print(f"✅ Markdown salvo em: {arquivo_md}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python html_to_markdown.py arquivo_entrada.html arquivo_saida.md")
    else:
        entrada, saida = sys.argv[1], sys.argv[2]
        if not os.path.exists(entrada):
            print(f"Erro: arquivo {entrada} não encontrado.")
        else:
            converter_arquivo_html(entrada, saida)
