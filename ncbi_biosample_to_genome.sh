#!/bin/bash
# Script para ler arquivo txt com lista de biosample e baixar genomas.
# By João Pitta (jlpitta82@gmail.com)
# At Home (Recife - PE)
# Tue 26 Aug 2025 15:42 BRT (Primeira versão)
set -euo pipefail

# ------------------------------------------------------------
# NCBI: BioSample (SAMN...) -> Assembly accession(s) -> FASTA
# Requisitos:
#   - Entrez Direct (esearch, esummary, xtract)
#   - NCBI Datasets CLI (datasets, dataformat)
#
# Uso:
#   ./ncbi_biosample_to_genome.sh -i biosamples.txt [-o saida]
#
#   biosamples.txt: um SAMN por linha
# ------------------------------------------------------------

# valores padrão
INPUT=""
OUTDIR="genomas_biosample"   # padrão se -o não for passado

# parsing de argumentos
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)
      INPUT="$2"; shift 2;;
    -o|--outdir)
      OUTDIR="$2"; shift 2;;
    -h|--help)
      echo "Uso: $0 -i arquivo_com_SAMNs.txt [-o pasta_de_saida]"
      exit 0;;
    *)
      echo "Parâmetro desconhecido: $1"; exit 1;;
  esac
done

# validações
if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
  echo "ERRO: forneça o arquivo com -i"; exit 1
fi

# criando pastas
mkdir -p "$OUTDIR"
mkdir -p "$OUTDIR/genomas"

# loop for lendo cada SAMN do arquivo
for SAMN in $(cat "$INPUT"); do
  echo ">>> Processando $SAMN"

  accs=$(esearch -db biosample -query "$SAMN" \
        | elink -target assembly \
        | esummary \
        | xtract -pattern DocumentSummary -element AssemblyAccession \
        || true)

  if [[ -z "$accs" ]]; then
    echo "   Nenhum assembly encontrado para $SAMN"
    continue
  fi

  echo "   Assemblies encontrados: $accs"

  accession=$(echo "$accs" | awk '{print $1}' | head -n1)

  if [[ "$accession" == GCA_* || "$accession" == GCF_* ]]; then
    echo "   Baixando $accession ..."

    # caminhos de saída dentro da pasta escolhida (-o)
    zipfile="${OUTDIR}/${accession}.zip"
    outdir_acc="${OUTDIR}/${accession}_genome"

    # baixa o pacote do NCBI Datasets
    echo "$accession" > /tmp/one.txt
    datasets download genome accession --inputfile /tmp/one.txt \
      --include genome \
      --filename "$zipfile" \
      --no-progressbar

    # extrai para subpasta específica
    unzip -o "$zipfile" -d "$outdir_acc" >/dev/null

    # procurar arquivos .fna (ou .fna.gz) e copiar/renomear
    fna_file=$(find "$outdir_acc" -type f -name "*.fna*" | head -n1)
    if [[ -n "$fna_file" ]]; then
      cp "$fna_file" "${OUTDIR}/genomas/${SAMN}.fna"
      echo "   Copiado como ${OUTDIR}/genomas/${SAMN}.fna"
    else
      echo "   Aviso: nenhum .fna encontrado em $outdir_acc"
    fi

  else
    echo "   Nenhum accession válido (GCA/GCF) para $SAMN"
  fi
  sleep 5
  echo -e "\n\n"
done

echo "✅ concluído. genomas renomeados em: $OUTDIR/genomas"
