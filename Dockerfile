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
# Versão do componente: vem do construtor (build-arg), sem valor padrão para não rotular a imagem errada.
ARG PRINTER_VERSION
RUN test -n "${PRINTER_VERSION}" || { echo "ERRO: passe --build-arg PRINTER_VERSION=<versão>" >&2; exit 1; }
LABEL maintainer="Rodrigo dos Santos Brandão <rodrigomicrosiga>" \
      version="${PRINTER_VERSION}" \
      description="TOTVS Printer - Delivery Container - Ultra Light"

# Usuário não-root: este container só extrai um arquivo pro volume compartilhado
# e fica em standby, não precisa de privilégio nenhum.
RUN addgroup -S printer && adduser -S -G printer printer

WORKDIR /tmp

# Cria o ponto de montagem do volume compartilhado do Printer
RUN mkdir -p /mnt/printer_shared && chown -R printer:printer /mnt/printer_shared

# Copia os arquivos limpos do estágio do builder para a pasta correta do printer
COPY --from=builder --chown=printer:printer /tmp/build/printer /tmp/printer

COPY --chown=printer:printer ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER printer

# Checa se algo realmente foi provisionado no volume compartilhado.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD find /mnt/printer_shared -mindepth 1 -print -quit | grep -q .

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]