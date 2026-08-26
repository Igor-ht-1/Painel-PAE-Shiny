# Painel PAE — Avaliação de Acurácia MapBiomas

Uma aplicação **R/Shiny** interativa e moderna para análise, visualização e validação da acurácia do mapeamento MapBiomas. O painel calcula automaticamente indicadores globais, gera matrizes de confusão proporcionais e exibe séries temporais detalhadas.

---

## 🚀 Como Executar o Projeto

**Não é necessário instalar manualmente nenhuma biblioteca do R.** O próprio script gerencia e instala todas as dependências automaticamente na primeira execução.

### Passos para inicialização:

1. Clone ou baixe este repositório para o seu computador.
2. Certifique-se de que os arquivos `.xlsx` estão dentro da pasta `Data/` (ou `data/`) no mesmo diretório do script.
3. Abra o arquivo do projeto no RStudio.
4. **Rode apenas o Bloco 1 do código (`carregar_dependencias()`)**:
   - Este bloco verifica se você já possui os pacotes necessários (`shiny`, `tidyverse`, `plotly`, `bslib`, `scales`, `shinycssloaders`, `readxl` e `shinyWidgets`).
   - Caso falte algum pacote, ele fará a instalação automática direto do CRAN e em seguida fará o carregamento de todos eles na sua sessão.
5. Em seguida, basta executar o restante do script ou clicar no botão **Run App** no canto superior do RStudio.

---

## 🛠️ Estrutura do Código

* **Bloco 1: Gerenciamento de Pacotes e Dependências** — Auto-instalação e carregamento automatizado de todas as bibliotecas necessárias.
* **Bloco 2: Configuração, Leitura e Tradução** — Detecção automática de diretórios, validação das planilhas de entrada e estruturação dos dados.
* **Bloco 3: Interface do Usuário (UI)** — Design responsivo em *Dark Mode* (`bslib`), com filtros dinâmicos e navegação por abas.
* **Bloco 4: Servidor (Server)** — Processamento reativo, cálculo das métricas de acurácia (AG, EG, EQ, EA, UA, PA, F1-Score) e renderização dos gráficos interativos.

---

## 📋 Pré-requisitos de Dados

Antes de rodar a aplicação, garanta que a pasta `Data/` contém os seguintes arquivos:
* `ALL_CLASSES.xlsx` — Tabela oficial com a legenda e codificação de classes do MapBiomas.
* Tabela(s) no formato `*confusion*.xlsx` — Matrizes de confusão brutas/proporcionais.
* Tabela(s) no formato `*metrics*.xlsx` — Métricas globais e por classe pré-calculadas.

---

## 📊 Principais Funcionalidades

* **Filtros Personalizados**: Seleção por Nível de Legenda (L1, L2 ou L3), Região/Bioma, Anos da série e Classes específicas.
* **Cards de Resumo Global**: Métricas instantâneas de Acurácia Global (AG), Erro Global (EG), Erro de Quantidade (EQ) e Erro de Alocação (EA).
* **Gráficos Interativos**: 
  * Visualização no estilo piramidal para Acurácia do Usuário (UA) vs Erro de Comissão, e Acurácia do Produtor (PA) vs Erro de Omissão.
  * Série temporal da Acurácia Global ao longo dos anos selecionados.
  * Heatmap da Matriz Proporcional com opção de alternar a visualização entre **porcentagem** e **quantidade de amostras estimadas**.
