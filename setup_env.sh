#!/usr/bin/env bash
set -euo pipefail
# Script montar o ambiente mamba com dependências para o script ncbi_biosample_to_genome.sh.
# By João Pitta (jlpitta82@gmail.com)
# At Home (Recife - PE)
# Tue 26 Aug 2025 15:42 BRT (Primeira versão)

# ------------------------------------------------------------
# Script para criar ambiente mamba "baixagenomasbiosample"
# e instalar as dependências necessárias para rodar
# ncbi_biosample_to_genome.sh
#
# Dependências instaladas:
#   - entrezdirect (edirect -> esearch, esummary, xtract...)
#   - ncbi-datasets-cli (datasets)
#   - unzip, wget
# ------------------------------------------------------------

# Verifica se mamba está disponível
if ! command -v mamba >/dev/null 2>&1; then
  echo "ERRO: mamba não encontrado no PATH."
  echo "Instale micromamba ou mamba primeiro."
  exit 1
fi

# Nome do ambiente
ENVNAME="baixagenomasbiosample"

# Criação do ambiente com os pacotes necessários
mamba create -y -n "$ENVNAME" -c conda-forge -c bioconda \
  entrez-direct \
  ncbi-datasets-cli \
  unzip \
  wget

# Ativação do ambiente
echo "--------------------------------------------------"
echo "Ambiente '$ENVNAME' criado com sucesso!"
echo
echo "Para ativar, use:"
echo "   mamba activate $ENVNAME"
echo
echo "Depois, rode seu script:"
echo "   ./ncbi_biosample_to_genome.sh -i biosamples.txt -o saida"
echo "--------------------------------------------------"
