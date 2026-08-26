# Painel PAE - Painel para Análise de Acurácia 
[![R-Shiny](https://img.shields.io/badge/R-Shiny-blue.svg)](https://shiny.posit.co/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Institution](https://img.shields.io/badge/UFG-LAPIG-green.svg)](https://lapig.iesa.ufg.br/)
O **Painel PAE (Painel para Análise de Acurácia)** é uma aplicação interativa desenvolvida em 
linguagem **R** e ecossistema **Shiny** para automação de testes de validação cartográfica e acurácia 
temática de mapeamentos geoespaciais. 
O projeto foi desenvolvido no âmbito do Programa Institucional de Bolsas de Iniciação Científica 
(**PIBIC**) junto ao **Laboratório de Processamento de Imagens e Geoprocessamento (LAPIG)** da 
**Universidade Federal de Goiás (UFG)**, atuando diretamente no suporte e validação dos dados da rede 
**MapBiomas**.
---
## Funcionalidades Principais
- **Cálculo de Matrizes de Confusão Populacionais:** Matrizes ponderadas e proporções de área (p_ij) 
calculadas de forma vetorizada.
- **Incorporação do Peso Amostral Real:** Cálculo de frequência ponderada utilizando a variável de 
amostragem peso = 1 / peso_vot, garantindo estimativas populacionais não tendenciosas (design-based 
inference).
- **Métricas de Desempenho Cartográfico:**
 - Acurácia Global (AG)
 - Acurácia do Usuário (AU)
 - Acurácia do Produtor (AP)
- **Decomposição de Erros (Pontius Jr. & Millones, 2011):** Separação precisa entre **Erro de 
Quantidade (Q)** e **Erro de Alocação (A)**.
- **Otimização Computacional & Programação Defensiva:**
 - Processamento reativo centralizado para suporte a milhões de registros.
 - Verificação condicional de integridade em bases legadas para prevenção de falhas (crashes).
- **Visualização Interativa:** Gráficos e matrizes dinâmicas via `Plotly` e `Highcharter`.
---
## Estrutura do Repositório
```text
.
├── Tabelas.zip # Pacote contendo os scripts do Shiny e bases de dados/matrizes
├── README.md # Documentação técnica do projeto
└── LICENSE # Licença MIT
```
> **Nota:** Para executar o dashboard, extraia o conteúdo do arquivo `Tabelas.zip` no diretório de 
trabalho do R.
---
## Pré-requisitos e Instalação
Para rodar a aplicação localmente, certifique-se de ter o **R** (versão 4.0 ou superior) e o 
**RStudio** instalados.

### Pacotes Necessários
Execute no seu console R para instalar as dependências:
```R
install.packages(c(
 "shiny",
 "shinydashboard",
 "tidyverse",
 "plotly",
 "highcharter",
 "DT",
 "survey"
))
```
---
## Como Executar o Aplicativo
1. Clone o repositório ou faça o download dos arquivos:
 ```bash
 git clone https://github.com/Igor-ht-1/painel-pae-shiny.git
 ```
2. Descompacte o arquivo `Tabelas.zip` na raiz do projeto.
3. Abra o RStudio e execute a aplicação:
 ```R
 shiny::runApp()
 ```
---
## Fundamentação Teórica & Referências
- **Pontius Jr, R. G.; Millones, M.** (2011). *Death to Kappa: birth of quantity response and 
allocation disagreement alternatives to Kappa*. International Journal of Remote Sensing, v. 32, n. 
15, p. 4407-4429.
- **MapBiomas.** Mapeamento Anual da Cobertura e Uso da Terra no Brasil. Disponível em: 
[mapbiomas.org](https://mapbiomas.org/).
- **Wickham, H. et al.** (2021). *Mastering Shiny: Build Interactive Apps, Reports, and Dashboards 
Powered by R*. O'Reilly Media.
---
## Autor e Orientação
- **Autor:** Igor Rodrigues Soares Santos
- **Orientador:** Prof. Dr. Luis Rodrigo Fernandes Baumann
- **Instituição:** Instituto de Matemática e Estatística (IME) / LAPIG - Universidade Federal de 
Goiás (UFG)
- **Projeto PIBIC:** *Estudos em Estatística, Matemática Aplicada e Ciência de Dados*