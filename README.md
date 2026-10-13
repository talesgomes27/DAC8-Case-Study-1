# Cyclistic Bike-Share: Análise de Padrões e Conversão de Usuários

Estudo de caso desenvolvido sobre os dados públicos do sistema de compartilhamento de bicicletas de Chicago (Divvy/Cyclistic). O projeto analisa padrões de uso entre membros anuais e ciclistas casuais para subsidiar estratégias de conversão de planos.

Relatório completo publicado em: [talesgomes27.github.io/DAC8-Case-Study-1](https://talesgomes27.github.io/DAC8-Case-Study-1/)

---

## Destaques Analíticos

* **Finalidade de uso contrastante**: Membros anuais utilizam as bicicletas predominantemente para transporte utilitário em dias úteis, com picos evidentes às 8h e 17h. Ciclistas casuais concentram o volume em tardes ensolaradas e fins de semana.
* **Duração e comportamento de rota**: Ciclistas casuais registram duração mediana superior a 30 minutos (contra 12 minutos dos membros) e realizam proporção significativamente maior de rotas circulares (início e término na mesma estação).
* **Validação estatística**: Teste de postos de Wilcoxon confirma diferença estatisticamente significante na distribuição de tempos de viagem entre os dois grupos ($p < 2.2 \times 10^{-16}$).
* **Segmento comutador oculto**: Aproximadamente 10,7% das corridas casuais ocorrem em dias úteis, nos horários de pico comercial, ponto a ponto e com duração menor que 45 minutos. Esse grupo representa o público prioritário para campanhas de conversão.

---

## Estrutura do Repositório

```
DAC8-Case-Study-1/
├── _quarto.yml                     # Configuração global do projeto Quarto
├── README.md                       # Documentação e instruções de reprodução
├── DAC8-Case-Study-1.pdf          # Especificação original do estudo de caso
├── data/
│   ├── generate_sample.R           # Gerador de amostra sintética estruturada
│   ├── sample_tripdata.csv         # Amostra para testes e compilação imediata
│   └── raw/                        # Diretório local para os CSVs brutos (ignorado no Git)
├── R/
│   ├── 01_ingest.R                 # Ingestão resiliente com fallback automático
│   ├── 02_clean_and_transform.R    # Limpeza, Haversine e engenharia de variáveis
│   ├── 03_statistical_analysis.R   # Testes não paramétricos e segmentação
│   └── 04_theme_cyclistic.R        # Identidade visual e funções para ggplot2
├── report/
│   ├── index.qmd                   # Relatório executivo moderno em Quarto
│   ├── custom.scss                 # Estilos customizados e cartões de KPI
│   └── assets/                     # Imagens e ícones de apoio
└── docs/
    └── index.html                  # Build HTML publicado no GitHub Pages
```

---

## Como Reproduzir

### 1. Pré-requisitos
* R (versão $\ge$ 4.1) com pacotes: `tidyverse`, `lubridate`, `scales`, `knitr`.
* [Quarto CLI](https://quarto.org/) instalado.

### 2. Execução Local
1. Clone este repositório:
   ```bash
   git clone https://github.com/talesgomes27/DAC8-Case-Study-1.git
   cd DAC8-Case-Study-1
   ```

2. (Opcional) Adicione os 12 arquivos mensais brutos em `data/raw/`. Caso não adicione, o pipeline utilizará automaticamente a base de teste em `data/sample_tripdata.csv`.

3. Renderize o relatório final:
   ```bash
   quarto render report/index.qmd
   ```
   O arquivo consolidado será gerado em `report/index.html`.
