#!/bin/sh
set -e

echo "📦 [Printer Delivery] Inicializando provisionamento do TOTVS Printer v3.0.5..."

TARGET_DIR="/mnt/printer_shared"

# 🧹 Limpeza cirúrgica sem tentar deletar pastas presas pelo Kernel
echo "🧹 Limpando resíduos antigos de forma segura..."
if [ -d "$TARGET_DIR" ]; then
    # Encontra e deleta arquivos normais de forma silenciosa na raiz do volume
    find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type f -delete 2>/dev/null || true
fi

echo "📂 Provisionando executáveis do TOTVS Printer na raiz do volume..."

# 🚀 CÓPIA CIRÚRGICA: Garante que os binários do printer sejam copiados para a raiz do volume compartilhado
if [ -d "/tmp/printer" ]; then
    cp -r /tmp/printer/* "$TARGET_DIR/"
else
    echo "❌ Erro crítico: Arquivos do printer não localizados em /tmp/printer"
    exit 1
fi

echo "✅ TOTVS Printer v3.0.5 provisionado com sucesso no volume compartilhado!"
echo "💤 Mantendo container em standby para governança do volume."

# Mantém o container vivo sem consumo de CPU
exec tail -f /dev/null

# CI/CD Trigger Checksum: v1.0.0