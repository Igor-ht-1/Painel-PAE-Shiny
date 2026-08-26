# Painel PAE - Painel para Análise de Acurácia 
[![R-Shiny](https://img.shields.io/badge/R-Shiny-blue.svg)](https://shiny.posit.co/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Institution](https://img.shields.io/badge/UFG-LAPIG-green.svg)](https://lapig.iesa.ufg.br/)
O **Painel PAE (Painel para Análise de Acurácia)** é uma aplicação interativa desenvolvida em linguagem **R** e 
ecossistema **Shiny** para automação de testes de validação cartográfica e acurácia temática de mapeamentos 
geoespaciais. 
O projeto foi desenvolvido no âmbito do Programa Institucional de Bolsas de Iniciação Científica (**PIBIC**) 
junto ao **Laboratório de Processamento de Imagens e Geoprocessamento (LAPIG)** da **Universidade Federal de 
Goiás (UFG)**, atuando diretamente no suporte e validação dos dados da rede **MapBiomas**.
---
## Funcionalidades Principais
- **Detecção Automática de Dados:** Reconhece e consolida automaticamente os arquivos da pasta `Data/` 
(suportando diferentes coleções e níveis de legenda `L1`, `L2`, `L3`).
- **Cálculo de Matrizes de Confusão Populacionais:** Matrizes de proporção de área (p_ij) agregadas por região, 
ano e nível.
- **Métricas Globais e Específicas:**
 - Acurácia Global (AG / OA)
 - Erro Global (EG)
 - Erro de Quantidade (EQ) e Erro de Alocação (EA) — *(Pontius Jr. & Millones, 2011)*
- **Análise por Classe:**
 - Gráficos no formato "pirâmide" comparando **Acurácia do Usuário (AU)** x **Erro de Comissão** e **Acurácia do 
Produtor (AP)** x **Erro de Omissão**.
 - Cálculo do **Score F1** por classe.
 - Alternância de matriz de confusão entre **Porcentagem** e **Quantidade Estimada de Amostras**.
- **Análise Temporal:** Série histórica de Acurácia Global interativa por região/bioma.
- **Interface Moderna:** Desenvolvida em **bslib** com tema dark nativo (`#181a1b`) e responsividade para 
diferentes resoluções.
---
## Estrutura do Repositório
```text
.
├── Data/ # Pasta contendo as tabelas do MapBiomas
│ ├── ALL_CLASSES.xlsx # Tabela oficial de legenda e classes
│ ├── tabela_mapbiomas_confusion_*.xlsx
│ └── tabela_mapbiomas_metrics_*.xlsx
├──PAE.R # Código-fonte principal da aplicação Shiny
├── Tabelas.zip # Backup compactado dos dados
├── README.md # Documentação técnica do projeto
└── LICENSE # Licença MIT
```
---
## Pré-requisitos e Instalação
Para rodar a aplicação localmente, certifique-se de ter o **R** (versão 4.0 ou superior) e o **RStudio** 
instalados.
### Pacotes Necessários
O próprio script instala automaticamente os pacotes ausentes, mas você também pode instalá-los manualmente 
executando:
```R
install.packages(c(
 "shiny",
 "tidyverse",
 "plotly",
 "bslib",
 "scales",
 "shinycssloaders",
 "readxl",
"shinyWidgets"
))
```
---
## Como Executar o Aplicativo
1. Clone o repositório ou faça o download do projeto:
 ```bash
 git clone https://github.com/Igor-ht-1/painel-pae-shiny.git
 ```
2. Garanta que as tabelas de métricas, confusão e o arquivo `ALL_CLASSES.xlsx` estejam localizados na pasta 
**`Data/`**.
3. Abra o script no RStudio e clique no botão **"Run App"** (ou execute no console):
 ```R
 shiny::runApp("PAE.R")
 ```
---
## Fundamentação Teórica & Referências
- **Pontius Jr, R. G.; Millones, M.** (2011). *Death to Kappa: birth of quantity response and allocation 
disagreement alternatives to Kappa*. International Journal of Remote Sensing, v. 32, n. 15, p. 4407-4429.
- **MapBiomas.** Mapeamento Anual da Cobertura e Uso da Terra no Brasil. Disponível em: [mapbiomas.org](https://
mapbiomas.org/).
---
## Autor e Orientação
- **Autor:** Igor Rodrigues Soares Santos
- **Orientador:** Prof. Dr. Luis Rodrigo Fernandes Baumann
- **Instituição:** Instituto de Matemática e Estatística (IME) / LAPIG - Universidade Federal de Goiás (UFG)