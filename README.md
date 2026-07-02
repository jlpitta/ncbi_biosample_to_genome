# ncbi_biosample_to_genome

Baixa genomas (FASTA) do NCBI a partir de uma lista de BioSamples (SAMN...).

Para cada BioSample, resolve o(s) Assembly accession(s) associado(s) via Entrez Direct, baixa o pacote via NCBI Datasets CLI, e salva o `.fna` renomeado com o próprio BioSample.

## Setup

```bash
./setup_env.sh
mamba activate baixagenomasbiosample
```

## Uso

```bash
./ncbi_biosample_to_genome.sh -i biosamples.txt [-o pasta_de_saida]
```

- `-i`: arquivo texto com um SAMN por linha (obrigatório)
- `-o`: pasta de saída (padrão: `genomas_biosample`)

Genomas finais ficam em `<pasta_de_saida>/genomas/<SAMN>.fna`.
