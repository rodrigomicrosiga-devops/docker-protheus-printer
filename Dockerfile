# ==============================================================================
# ESTÁGIO 1: Builder (Extração e Limpeza por Strip)
# ==============================================================================
FROM alpine:3.19 AS builder

RUN apk add --no-cache tar binutils

WORKDIR /tmp/build

# 🌟 SUPORTE DINÂMICO: Copia o pacote do Printer ignorando caixa alta/baixa no nome, exigindo .tar.gz
COPY ./*[pP][rR][iI][nN][tT][eE][rR]*.[tT][aA][rR].[gG][zZ] ./printer.tar.gz

RUN mkdir -p printer && \
    tar -xzf printer.tar.gz -C printer/

# ⚡ A MÁGICA DO STRIP: Remove símbolos de depuração de binários e libs compiladas (.so)
RUN find printer/ -type f -exec strip --strip-unneeded {} + 2>/dev/null || true

# ==============================================================================
# ESTÁGIO 2: Runner (Imagem Enxuta de Delivery)
# ==============================================================================
FROM alpine:3.19 AS runner
LABEL maintainer="Rodrigo dos Santos Brandão <rodrigomicrosiga>" \
      version="3.0.5" \
      description="TOTVS Printer - Delivery Container - Ultra Light"

WORKDIR /tmp

# Cria o ponto de montagem do volume compartilhado do Printer
RUN mkdir -p /mnt/printer_shared

# Copia os arquivos limpos do estágio do builder para a pasta correta do printer
COPY --from=builder /tmp/build/printer /tmp/printer

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]