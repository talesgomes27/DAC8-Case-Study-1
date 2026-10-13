# Cyclistic Bike-Share: Análise de Padrões e Conversão de Usuários

Estudo de caso desenvolvido sobre a base pública de viagens do sistema de compartilhamento de bicicletas de Chicago (Divvy/Cyclistic), cobrindo integralmente as seis fases metodológicas do Google Data Analytics (**Ask, Prepare, Process, Analyze, Share, Act**).

Relatório completo publicado em: [talesgomes27.github.io/DAC8-Case-Study-1](https://talesgomes27.github.io/DAC8-Case-Study-1/)

---

## Síntese do Problema de Negócio

A diretora de marketing Lily Moreno busca desenhar campanhas orientadas a dados para converter ciclistas casuais (passes avulsos e diários) em membros anuais. Membros anuais asseguram maior estabilidade de receita e margem operacional por cliente, amortizando os custos fixos da frota durante as quatro estações de Chicago.

A análise comprova que os dois grupos utilizam o sistema com propósitos divergentes: membros empregam as bicicletas como transporte corporativo diário; ciclistas casuais concentram o uso em lazer e passeios nos fins de semana e tardes de verão.

---

## Destaques Metodológicos e Estatísticos

* **Governança ROCCC e Tratamento de PII**: Avaliação formal de confiabilidade (*Reliable, Original, Comprehensive, Current, Cited*). Como a base não armazena identificadores pessoais por razões de privacidade, a unidade de análise é a **viagem**, contornando a restrição através de padrões agregados de rotas e janelas horárias.
* **Funil de Integridade em Estágios**: Descarte documentado de viagens com timestamps invertidos, testes de doca com falha ($< 2$ minutos), anomalias de manutenção ou bicicletas esquecidas ($> 24$ horas) e coordenadas geográficas fora da malha de Chicago.
* **Engenharia de Atributos Espaço-Temporais**: Cálculo de distância geodésica em quilômetros via fórmula vetorizada de Haversine, velocidade média aproximada, indicador de rotas circulares (origem igual ao destino) e calibração das estações climáticas locais.
* **Estatística Descritiva Canônica**: Cálculo de médias, medianas, desvio-padrão, intervalo interquartil (IQR), limites e a moda do dia da semana (quarta-feira para membros; sábado para casuais).
* **Inferência Não Paramétrica e Tamanho de Efeito**:
  - Teste de postos de Wilcoxon-Mann-Whitney confirma diferença significativa nas durações ($W = 3.19 \times 10^{12}$, $p < 2.2 \times 10^{-16}$).
  - Testes Qui-quadrado de independência com cálculo de $V$ de Cramér para tipos de dia, modalidades de bicicleta e circuitos fechados (casuais realizam mais de 4x mais rotas circulares: 13,7% vs 3,3%).
* **Modelo Logístico Explicativo**: Regressão logística binomial reportando *Odds Ratios* ($\text{OR}$) com intervalos de confiança de 95%. Viagens em horários de pico comercial (7h–9h e 16h–18h) apresentam $\text{OR} = 1,35$ ($p < 0,001$), elevando em 35% a propensão de comportamento de membro, enquanto fins de semana reduzem essa chance em 45% ($\text{OR} = 0,55$).
* **Segmentação em Três Personas de Casuais**:
  - *Comutador Oculto* (16,8% do volume casual, somando 316.203 viagens): Viagens em dias úteis nos horários de pico comercial, ponto a ponto e com duração inferior a 45 minutos. Público prioritário para campanhas de conversão.
  - *Lazer de Fim de Semana* (49,3%): Trajetos recreativos aos sábados, domingos e circuitos fechados na orla.
  - *Espontâneo / Noturno* (33,9%): Viagens esporádicas fora dos horários de expediente.
* **Recomendações com Desenho de Teste A/B**: Campanha digital in-app com calculadora de economia para o comutador oculto, criação de passe sazonal de primavera/verão e plano experimental de validação com grupo de controle.

---

## Estrutura do Repositório

```
DAC8-Case-Study-1/
├── _quarto.yml                     # Configuração global do projeto Quarto
├── README.md                       # Documentação técnica e instruções
├── DAC8-Case-Study-1.pdf          # Especificação original do estudo de caso
├── data/
│   ├── generate_sample.R           # Gerador da amostra sintética estruturada
│   ├── sample_tripdata.csv         # Amostra de 10.000 linhas para testes imediatos
│   └── raw/                        # Diretório para CSVs brutos completos (ignorado no Git)
├── R/
│   ├── 01_ingest.R                 # Ingestão com tipagem e fallback automático
│   ├── 02_clean_and_transform.R    # Limpeza, Haversine e engenharia de variáveis
│   ├── 03_statistical_analysis.R   # Descritiva canônica, Wilcoxon, modelo logístico e personas
│   └── 04_theme_cyclistic.R        # Identidade visual, tema acessível e 9 funções gráficas
├── report/
│   ├── index.qmd                   # Relatório executivo completo nas seis fases canônicas
│   ├── custom.scss                 # Estilos customizados, grid e cartões de KPI
│   └── assets/                     # Ícones e imagens do relatório
└── docs/
    └── index.html                  # Build HTML compilado publicado no GitHub Pages
```

---

## Como Reproduzir o Estudo

### 1. Pré-requisitos
* R (versão $\ge$ 4.1) com os pacotes: `tidyverse`, `lubridate`, `scales`, `knitr`.
* [Quarto CLI](https://quarto.org/) instalado.

### 2. Execução Local
1. Clone o repositório:
   ```bash
   git clone https://github.com/talesgomes27/DAC8-Case-Study-1.git
   cd DAC8-Case-Study-1
   ```

2. (Opcional) Insira os 12 arquivos mensais brutos em `data/raw/`. Sem eles, o pipeline utiliza automaticamente `data/sample_tripdata.csv`.

3. Compile o relatório completo:
   ```bash
   quarto render report/index.qmd
   ```
   A saída será gerada em `report/index.html`.
