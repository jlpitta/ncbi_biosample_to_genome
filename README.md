# ncbi_biosample_to_genome

Script em Bash para baixar genomas do NCBI a partir de uma lista de identificadores BioSample (`SAMN...`).

Dado um arquivo de texto com um BioSample por linha, o script resolve o Assembly correspondente a cada um, baixa o pacote de genoma através do NCBI Datasets CLI e salva o arquivo FASTA final já renomeado com o próprio BioSample de origem.

## Sumário

- [Visão geral](#visão-geral)
- [Como funciona](#como-funciona)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Uso](#uso)
- [Estrutura de saída](#estrutura-de-saída)
- [Exemplo completo](#exemplo-completo)
- [Limitações conhecidas](#limitações-conhecidas)

## Visão geral

O NCBI não permite baixar um genoma diretamente a partir de um BioSample: é necessário primeiro descobrir qual Assembly está associado àquele BioSample, e só então baixar o pacote de arquivos desse Assembly. Este script automatiza essa cadeia:

```
BioSample (SAMN...) --> Assembly accession (GCA_/GCF_) --> pacote de genoma --> FASTA (.fna)
```

O resultado final é uma pasta com um `.fna` por BioSample, nomeado com o próprio identificador de entrada — o que facilita rastrear qual arquivo pertence a qual amostra, sem precisar guardar de cabeça o accession do Assembly.

## Como funciona

O script processa o arquivo de entrada linha a linha. Para cada BioSample:

1. **Resolução do Assembly.** Usa Entrez Direct para consultar o NCBI:
   - `esearch -db biosample` localiza o registro do BioSample;
   - `elink -target assembly` navega até o(s) Assembly(s) vinculado(s);
   - `esummary` obtém o resumo de cada Assembly;
   - `xtract` extrai o campo `AssemblyAccession` (ex.: `GCA_000123456.1`).

2. **Seleção do accession.** Se nenhum Assembly for encontrado, o BioSample é pulado e o script segue para o próximo. Se houver mais de um Assembly associado, apenas o **primeiro** da lista retornada é utilizado — os demais são descartados.

3. **Validação.** O accession selecionado precisa começar com `GCA_` ou `GCF_`; caso contrário, o BioSample é descartado com um aviso.

4. **Download.** O accession válido é baixado com o NCBI Datasets CLI (`datasets download genome accession`), gerando um arquivo `.zip` dentro da pasta de saída.

5. **Extração.** O `.zip` é descompactado em uma subpasta própria (`<accession>_genome`).

6. **Renomeação.** O script localiza o arquivo `.fna` (ou `.fna.gz`) dentro do pacote extraído e o copia para `genomas/<BioSample>.fna`, dentro da pasta de saída.

7. **Throttling.** Há uma pausa de 5 segundos entre um BioSample e o próximo, para não sobrecarregar a API do NCBI.

Ao final da execução, todos os genomas processados com sucesso estarão consolidados em `<pasta_de_saída>/genomas/`.

## Requisitos

- **Entrez Direct** (`esearch`, `elink`, `esummary`, `xtract`)
- **NCBI Datasets CLI** (`datasets`, `dataformat`)
- **unzip**
- **wget**
- **mamba** ou **micromamba** (para o script de instalação automatizada)

## Instalação

O ambiente com todas as dependências pode ser criado automaticamente com `setup_env.sh`, que usa mamba para montar um ambiente isolado chamado `baixagenomasbiosample`:

```bash
./setup_env.sh
mamba activate baixagenomasbiosample
```

Caso prefira instalar manualmente, sem o script de setup:

```bash
mamba create -n baixagenomasbiosample -c conda-forge -c bioconda \
  entrez-direct ncbi-datasets-cli unzip wget
mamba activate baixagenomasbiosample
```

## Uso

```bash
./ncbi_biosample_to_genome.sh -i biosamples.txt [-o pasta_de_saida]
```

### Parâmetros

| Parâmetro | Obrigatório | Descrição | Padrão |
|---|---|---|---|
| `-i`, `--input` | Sim | Arquivo de texto com um BioSample (`SAMN...`) por linha | — |
| `-o`, `--outdir` | Não | Pasta onde os resultados serão salvos | `genomas_biosample` |
| `-h`, `--help` | Não | Exibe a mensagem de uso e encerra | — |

### Formato do arquivo de entrada

Um BioSample por linha, sem cabeçalho:

```
SAMN12345678
SAMN23456789
SAMN34567890
```

## Estrutura de saída

Considerando `-o resultado`, a árvore de diretórios gerada é:

```
resultado/
├── GCA_000123456.1.zip
├── GCA_000123456.1_genome/
│   └── ... (conteúdo extraído do pacote do NCBI Datasets)
├── GCA_000234567.1.zip
├── GCA_000234567.1_genome/
│   └── ...
└── genomas/
    ├── SAMN12345678.fna
    └── SAMN23456789.fna
```

Os arquivos `.zip` e as pastas `<accession>_genome` são mantidos como está (não removidos automaticamente ao final). Os genomas finais, já renomeados por BioSample, ficam em `genomas/`.

## Exemplo completo

```bash
mamba activate baixagenomasbiosample

./ncbi_biosample_to_genome.sh -i biosamples.txt -o resultado

ls resultado/genomas/
```

## Limitações conhecidas

- Quando um BioSample está associado a mais de um Assembly, apenas o primeiro retornado pela consulta é baixado; os demais são ignorados silenciosamente (só aparecem no log de execução).
- Não há retry automático em caso de falha de rede ou indisponibilidade da API do NCBI — o BioSample problemático é simplesmente pulado.
- O intervalo fixo de 5 segundos entre requisições é uma medida conservadora de throttling, mas pode tornar a execução lenta para listas grandes de BioSamples.
