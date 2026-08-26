# ==============================================================================
# BLOCO 1: GERENCIAMENTO DE PACOTES E DEPENDENCIAS
# ==============================================================================
carregar_dependencias <- function() {
  pacotes <- c("shiny", "tidyverse", "plotly", "bslib", "scales", "shinycssloaders", "readxl", "shinyWidgets")
  faltantes <- pacotes[!(pacotes %in% installed.packages()[, "Package"])]
  if (length(faltantes) > 0) {
    install.packages(faltantes, dependencies = TRUE, repos = "https://cloud.r-project.org/")
  }
  library(shiny)
  library(tidyverse)
  library(plotly)
  library(bslib)
  library(scales)
  library(shinycssloaders)
  library(readxl) 
  library(shinyWidgets)
}
carregar_dependencias()

# ==============================================================================
# BLOCO 2: CONFIGURACAO, LEITURA E TRADUCAO AUTOMATICA DE LEGENDA
# ==============================================================================
# Detecta automaticamente a pasta onde este script esta salvo, para que o app
# funcione em qualquer computador -- basta que o script fique na MESMA PASTA
# das planilhas do MapBiomas (nao precisa editar nenhum caminho manualmente).
detectar_pasta_do_app <- function() {
  # 1) Rodando dentro do RStudio (botao "Run App" ou "Source")
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    ctx <- tryCatch(rstudioapi::getSourceEditorContext(), error = function(e) NULL)
    if (!is.null(ctx) && nzchar(ctx$path)) return(dirname(ctx$path))
  }
  # 2) Rodando via "Rscript novoapp.R" no terminal
  args <- commandArgs(trailingOnly = FALSE)
  arq <- sub("^--file=", "", args[grepl("^--file=", args)])
  if (length(arq) > 0) return(dirname(normalizePath(arq)))
  # 3) Ultimo recurso: pasta de trabalho atual
  getwd()
}

caminho_projeto <- detectar_pasta_do_app()

# Confere se as planilhas necessarias estao na pasta detectada e avisa
# claramente (em vez de travar com um erro tecnico confuso) se algo faltar.
verificar_pasta_de_dados <- function(caminho) {
  faltando <- c()
  if (!file.exists(file.path(caminho, "ALL_CLASSES.xlsx"))) {
    faltando <- c(faltando, "ALL_CLASSES.xlsx")
  }
  if (length(list.files(caminho, pattern = ".*confusion.*\\.xlsx$", ignore.case = TRUE)) == 0) {
    faltando <- c(faltando, "tabela(s) de 'confusion' (ex: tabela_mapbiomas_confusion_col10_l1.xlsx)")
  }
  if (length(list.files(caminho, pattern = ".*metrics.*\\.xlsx$", ignore.case = TRUE)) == 0) {
    faltando <- c(faltando, "tabela(s) de 'metrics' (ex: tabela_mapbiomas_metrics_col10_l1.xlsx)")
  }
  if (length(faltando) > 0) {
    stop(
      "\n\n================ PAINEL PAE - ARQUIVOS NAO ENCONTRADOS ================\n",
      "O programa procurou os dados nesta pasta:\n  ", caminho, "\n\n",
      "E nao encontrou:\n  - ", paste(faltando, collapse = "\n  - "), "\n\n",
      "Solucao: coloque o arquivo deste script (novoapp.R) na MESMA PASTA\n",
      "das planilhas do MapBiomas (ALL_CLASSES.xlsx + as tabelas de confusion e metrics)\n",
      "e rode novamente. Isso vale para qualquer computador: e so descompactar\n",
      "o .zip recebido por e-mail e manter todos os arquivos juntos na mesma pasta.\n",
      "=========================================================================\n"
    )
  }
}

verificar_pasta_de_dados(caminho_projeto)

# Normaliza codigos numericos de classe para o mesmo formato em todas as tabelas.
# O Excel/readxl pode gravar um mesmo codigo como "11" numa planilha e "11.0"
# (ou com espacos) em outra; sem isso o left_join falha silenciosamente e a
# classe cai no fallback "Classe X" em vez do nome traduzido. Valores nao
# numericos (como "All") sao mantidos como estao.
normalizar_codigo <- function(x) {
  x <- trimws(x)
  num <- suppressWarnings(as.numeric(x))
  ifelse(is.na(num), x, as.character(as.integer(num)))
}

# 1. CARREGA A PLANILHA DE CLASSES OFICIAIS DO MAPBIOMAS
carregar_legenda_oficial <- function(caminho) {
  arq_legenda <- file.path(caminho, "ALL_CLASSES.xlsx")
  if (!file.exists(arq_legenda)) {
    stop("ERRO CRÍTICO: O arquivo 'ALL_CLASSES.xlsx' nao foi encontrado na pasta informada!")
  }
  
  legenda_bruta <- read_excel(arq_legenda, col_types = "text")
  
  # Remove o prefixo numerico do rotulo oficial (ex: "1. Floresta" -> "Floresta";
  # "1.1. Formacao Florestal" -> "Formacao Florestal"), mantendo so o nome da classe.
  limpar_rotulo <- function(x) {
    str_replace(x, "^[0-9]+(\\.[0-9]+)*\\.\\s*", "")
  }
  
  l1_dic <- legenda_bruta %>% select(val = l1_val, label = l1) %>% filter(!is.na(val) & !is.na(label)) %>% distinct(val, .keep_all = TRUE) %>% mutate(label = limpar_rotulo(label), val = normalizar_codigo(val))
  l2_dic <- legenda_bruta %>% select(val = l2_val, label = l2) %>% filter(!is.na(val) & !is.na(label)) %>% distinct(val, .keep_all = TRUE) %>% mutate(label = limpar_rotulo(label), val = normalizar_codigo(val))
  l3_dic <- legenda_bruta %>% select(val = l3_val, label = l3) %>% filter(!is.na(val) & !is.na(label)) %>% distinct(val, .keep_all = TRUE) %>% mutate(label = limpar_rotulo(label), val = normalizar_codigo(val))
  
  list(L1 = l1_dic, L2 = l2_dic, L3 = l3_dic)
}

legendas_niveis <- carregar_legenda_oficial(caminho_projeto)

# 2. CARREGA AS TABELAS DE CONFUSAO E METRICAS
ler_tabelas_consolidadas <- function(caminho) {
  lista_confusion <- list.files(path = caminho, pattern = ".*confusion.*\\.xlsx$", full.names = TRUE, ignore.case = TRUE)
  lista_metrics <- list.files(path = caminho, pattern = ".*metrics.*\\.xlsx$", full.names = TRUE, ignore.case = TRUE)
  
  if (length(lista_confusion) == 0 || length(lista_metrics) == 0) return(NULL)
  
  ler_com_nivel <- function(caminho_arq) {
    # IMPORTANTE: extrai o nivel apenas do FINAL do nome do arquivo (antes da extensao).
    # Usar a regex sobre o nome completo era um bug: nomes como "..._col10_l1.xlsx"
    # contem "l1" dentro de "coL10", entao o antigo str_extract() sempre encontrava
    # esse "l1" de "col10" primeiro e classificava TODOS os arquivos (inclusive os
    # de L2 e L3) como se fossem "L1".
    nome_sem_ext <- tools::file_path_sans_ext(basename(caminho_arq))
    nivel_tag <- str_extract(nome_sem_ext, "(?i)l[1-3]$") %>% toupper()
    if (is.na(nivel_tag)) nivel_tag <- "L1"
    read_excel(caminho_arq, col_types = "text") %>% mutate(nivel = nivel_tag)
  }
  
  df_conf <- map_df(lista_confusion, ler_com_nivel) %>%
    mutate(
      year = trimws(year),
      region = trimws(region),
      class = normalizar_codigo(class),
      reference = normalizar_codigo(reference),
      metric = trimws(metric),
      estimate = as.numeric(estimate),
      n = as.numeric(n)
    ) %>%
    filter(!is.na(estimate))
  
  df_metr <- map_df(lista_metrics, ler_com_nivel) %>%
    mutate(
      year = trimws(year),
      region = trimws(region),
      class = normalizar_codigo(class),
      reference = normalizar_codigo(reference),
      metric = trimws(metric),
      estimate = as.numeric(estimate),
      n = as.numeric(n)
    ) %>%
    filter(!is.na(estimate))
  
  list(confusion = df_conf, metrics = df_metr)
}

banco_dados <- ler_tabelas_consolidadas(caminho_projeto)

# Grafico estilo "piramide etaria": acerto a esquerda, nome da classe no meio,
# erro a direita. col_acerto/col_erro sao nomes de colunas (string) dentro de df.
grafico_piramide <- function(df, col_acerto, col_erro, label_acerto, label_erro, cor_acerto, cor_erro) {
  df <- df %>% arrange(Classe)
  ordem <- rev(unique(df$Classe))  # primeira classe (alfabetica) fica no topo do grafico
  df$Classe <- factor(df$Classe, levels = ordem)
  
  # painel esquerdo: ACERTO -- eixo invertido para a barra crescer para fora (para a esquerda)
  p_acerto <- plot_ly(df, x = df[[col_acerto]], y = ~Classe, type = "bar", orientation = "h",
                      marker = list(color = cor_acerto),
                      hovertemplate = paste0(label_acerto, ": %{x:.1%}<extra></extra>")) %>%
    layout(xaxis = list(title = label_acerto, tickformat = ".0%", autorange = "reversed",
                        showgrid = FALSE, color = "#e2e2e2"),
           yaxis = list(showticklabels = FALSE, title = ""))
  
  # painel central: apenas o nome da classe (sem barra)
  p_label <- plot_ly(df) %>%
    add_trace(x = rep(0.5, nrow(df)), y = ~Classe, type = "scatter", mode = "text",
              text = ~Classe, textfont = list(color = "#e2e2e2", size = 11), hoverinfo = "skip") %>%
    layout(xaxis = list(visible = FALSE, range = c(0, 1)),
           yaxis = list(showticklabels = FALSE, title = ""))
  
  # painel direito: ERRO -- cresce naturalmente para fora (para a direita)
  p_erro <- plot_ly(df, x = df[[col_erro]], y = ~Classe, type = "bar", orientation = "h",
                    marker = list(color = cor_erro),
                    hovertemplate = paste0(label_erro, ": %{x:.1%}<extra></extra>")) %>%
    layout(xaxis = list(title = label_erro, tickformat = ".0%", showgrid = FALSE, color = "#e2e2e2"),
           yaxis = list(showticklabels = FALSE, title = ""))
  
  subplot(p_acerto, p_label, p_erro, nrows = 1, widths = c(0.4, 0.2, 0.4), shareY = TRUE, titleX = TRUE) %>%
    layout(showlegend = FALSE, paper_bgcolor = "#181a1b", plot_bgcolor = "#181a1b",
           font = list(color = "#e2e2e2"))
}

# ==============================================================================
# BLOCO 3: UI (INTERFACE)
# ==============================================================================
tema_dark <- bs_theme(
  version = 5, bg = "#181a1b", fg = "#e2e2e2", primary = "#3d6b64",
  secondary = "#c79b6f", success = "#67b99a", warning = "#e1ad52",
  base_font = font_google("Roboto"), heading_font = font_google("Montserrat"),
  "navbar-bg" = "#121415", "navbar-color" = "#f1f1f1", "card-bg" = "#202324"
)

ui <- page_sidebar(
  title = tags$div(
    tags$strong("Painel PAE"),
    tags$span(" — Avaliação de Acurácia MapBiomas", style = "font-weight:400; opacity:0.8;"),
    style = "font-weight:600;"
  ),
  theme = tema_dark,
  
  sidebar = sidebar(
    width = 360,
    h5(" Filtros de Escopo"),
    selectInput("filtro_nivel", "Selecione o Nível de Legenda:", choices = c("L1", "L2", "L3"), selected = "L1"),
    pickerInput("filtro_regiao", "Selecione a(s) Região(ões)/Bioma(s):",
                choices = sort(unique(banco_dados$confusion$region)),
                selected = sort(unique(banco_dados$confusion$region))[1],
                multiple = TRUE,
                options = pickerOptions(actionsBox = TRUE, liveSearch = TRUE,
                                        selectedTextFormat = "count > 3",
                                        countSelectedText = "{0} região(ões) selecionada(s)",
                                        noneSelectedText = "Nenhuma região selecionada")),
    pickerInput("filtro_ano", "Selecione o(s) Ano(s):",
                choices = sort(unique(banco_dados$confusion$year), decreasing = TRUE),
                selected = sort(unique(banco_dados$confusion$year), decreasing = TRUE),
                multiple = TRUE,
                options = pickerOptions(actionsBox = TRUE, liveSearch = TRUE,
                                        selectedTextFormat = "count > 3",
                                        countSelectedText = "{0} ano(s) selecionado(s)",
                                        noneSelectedText = "Nenhum ano selecionado")),
    hr(),
    h5(" Filtros de Classes"),
    uiOutput("seletor_classes_dinamico"),
    actionButton("btn_todos_classe", "Selecionar Todas", icon = icon("check"), class = "btn-success w-100")
  ),
  
  navset_bar(
    nav_panel(
      title = "Resumo Global Estimado",
      p(textOutput("legenda_selecao", inline = TRUE), class = "text-muted small mb-2"),
      layout_columns(
        col_widths = c(3, 3, 3, 3),
        card(card_header("Acurácia Global (AG)", class = "text-center"),
             div(class = "text-center", h3(textOutput("AG_box"), class = "text-success"))),
        card(card_header("Erro Global (EG)", class = "text-center"),
             div(class = "text-center", h3(textOutput("EG_box"), class = "text-danger"))),
        card(card_header("Erro Quantidade (EQ)", class = "text-center"),
             div(class = "text-center", h3(textOutput("EQ_box"), class = "text-warning"))),
        card(card_header("Erro Alocação (EA)", class = "text-center"),
             div(class = "text-center", h3(textOutput("EA_box"), class = "text-primary")))
      ),
      card(card_header("Desempenho por Classe"),
           tabsetPanel(
             tabPanel("Usuário (UA)", withSpinner(plotlyOutput("grafico_UA"))),
             tabPanel("Produtor (PA)", withSpinner(plotlyOutput("grafico_PA"))),
             tabPanel("Acurácia Global (Série Temporal)", withSpinner(plotlyOutput("grafico_serie_temporal")))
           ))
    ),
    nav_panel(
      title = "Matriz Proporcional",
      layout_columns(
        col_widths = c(8, 4),
        card(card_header("Heatmap Matriz PIJ"),
             radioButtons("heatmap_modo", NULL,
                          choices = c("Porcentagem" = "pct", "Números (amostras estimadas)" = "num"),
                          selected = "pct", inline = TRUE),
             withSpinner(plotlyOutput("heatmap_mc"))),
        card(card_header("Métricas por Classe"),
             p(textOutput("modo_tabela_label", inline = TRUE), class = "text-muted small mb-2"),
             tableOutput("tabela_metrics_classe"))
      )
    )
  )
)

# ==============================================================
# BLOCO 4: SERVER (LOGICA)
# ==============================================================
server <- function(input, output, session) {
  
  # 1. Tabela de Confusão Traduzida e Filtrada pelo Nível Escolhido
  dados_base_confusion <- reactive({
    req(input$filtro_nivel, input$filtro_regiao, input$filtro_ano)
    
    dic_atual <- legendas_niveis[[input$filtro_nivel]]
    
    banco_dados$confusion %>%
      filter(nivel == input$filtro_nivel, region %in% input$filtro_regiao, year %in% input$filtro_ano) %>%
      left_join(dic_atual, by = c("class" = "val")) %>%
      rename(class_nome = label) %>%
      left_join(dic_atual, by = c("reference" = "val")) %>%
      rename(ref_nome = label) %>%
      mutate(
        class_nome = coalesce(class_nome, paste("Classe", class)),
        ref_nome = coalesce(ref_nome, paste("Classe", reference))
      )
  })
  
  # 2. Tabela de Métricas Traduzida e Filtrada pelo Nível Escolhido
  dados_base_metrics <- reactive({
    req(input$filtro_nivel, input$filtro_regiao, input$filtro_ano)
    
    dic_atual <- legendas_niveis[[input$filtro_nivel]]
    
    banco_dados$metrics %>%
      filter(nivel == input$filtro_nivel, region %in% input$filtro_regiao, year %in% input$filtro_ano) %>%
      left_join(dic_atual, by = c("class" = "val")) %>%
      rename(class_nome = label) %>%
      left_join(dic_atual, by = c("reference" = "val")) %>%
      rename(ref_nome = label) %>%
      mutate(
        # Se for a linha agregada "All", mantém "All", senão traduz usando o dicionário
        class_nome = ifelse(class == "All", "All", coalesce(class_nome, paste("Classe", class))),
        ref_nome = ifelse(reference == "All", "All", coalesce(ref_nome, paste("Classe", reference)))
      )
  })
  
  # 3. Serie temporal da Acuracia Global (OA), por regiao, ao longo dos anos selecionados
  dados_serie_temporal <- reactive({
    req(input$filtro_nivel, input$filtro_regiao, input$filtro_ano)
    
    banco_dados$metrics %>%
      filter(nivel == input$filtro_nivel, region %in% input$filtro_regiao, year %in% input$filtro_ano,
             metric == "OA", class == "All") %>%
      mutate(ano_num = as.integer(year)) %>%
      arrange(ano_num)
  })
  
  # Seletor dinâmico de classes baseado nas classes existentes naquele nível/ano/região
  output$seletor_classes_dinamico <- renderUI({
    df <- dados_base_confusion()
    req(nrow(df) > 0)
    choices <- sort(unique(c(df$class_nome, df$ref_nome)))
    checkboxGroupInput("filtro_classe", "Classes Visíveis:", choices = choices, selected = choices)
  })
  
  observeEvent(input$btn_todos_classe, {
    df <- dados_base_confusion()
    choices <- sort(unique(c(df$class_nome, df$ref_nome)))
    updateCheckboxGroupInput(session, "filtro_classe", selected = choices)
  })
  
  # Legenda explicando se os valores abaixo sao de uma unica combinacao ou uma media
  output$legenda_selecao <- renderText({
    req(input$filtro_regiao, input$filtro_ano)
    n_reg <- length(input$filtro_regiao)
    n_ano <- length(input$filtro_ano)
    if (n_reg == 1 && n_ano == 1) {
      paste0("Valores para ", input$filtro_regiao, " em ", input$filtro_ano, ".")
    } else {
      paste0("Média entre ", n_reg, " região(ões) e ", n_ano, " ano(s) selecionados.")
    }
  })
  
  # Cards da Primeira Aba (Resumo Global Estimado)
  output$AG_box <- renderText({
    # A tabela de metrics do MapBiomas usa a sigla "OA" (Overall Accuracy) e nao "AG".
    # Filtrar por "AG" nunca retornava linhas, entao o card sempre mostrava "0.0%".
    # Quando ha mais de uma regiao/ano selecionado, mostramos a media entre eles.
    v <- dados_base_metrics() %>% filter(metric == "OA", class == "All") %>% pull(estimate)
    if(length(v) == 0) "0.0%" else percent(mean(v, na.rm = TRUE), 0.1)
  })
  
  output$EG_box <- renderText({
    v <- dados_base_metrics() %>% filter(metric == "OA", class == "All") %>% pull(estimate)
    if(length(v) == 0) "0.0%" else percent(1 - mean(v, na.rm = TRUE), 0.1)
  })
  
  output$EQ_box <- renderText({
    v <- dados_base_metrics() %>% filter(metric == "QUANTITY", class == "All") %>% pull(estimate)
    if(length(v) == 0) "0.0%" else percent(mean(v, na.rm = TRUE), 0.1)
  })
  
  output$EA_box <- renderText({
    v <- dados_base_metrics() %>% filter(metric == "ALLOCATION", class == "All") %>% pull(estimate)
    if(length(v) == 0) "0.0%" else percent(mean(v, na.rm = TRUE), 0.1)
  })
  
  # Métricas compiladas diretamente da tabela 'metrics' traduzida
  # (com multi-selecao de regiao/ano pode haver mais de uma linha por classe,
  # entao agregamos pela media)
  metricas_classe_consolidadas <- reactive({
    df_m <- dados_base_metrics()
    req(input$filtro_classe, nrow(df_m) > 0)
    
    uas <- df_m %>% filter(metric == "UA", class_nome %in% input$filtro_classe) %>%
      group_by(Classe = class_nome) %>% summarise(UA = mean(estimate, na.rm = TRUE), .groups = "drop")
    pas <- df_m %>% filter(metric == "PA", ref_nome %in% input$filtro_classe) %>%
      group_by(Classe = ref_nome) %>% summarise(PA = mean(estimate, na.rm = TRUE), .groups = "drop")
    
    tibble(Classe = input$filtro_classe) %>%
      left_join(uas, by = "Classe") %>%
      left_join(pas, by = "Classe") %>%
      mutate(
        UA = coalesce(UA, 0),
        PA = coalesce(PA, 0),
        F1 = ifelse((UA + PA) == 0, 0, 2 * (UA * PA) / (UA + PA))
      )
  })
  
  output$grafico_UA <- renderPlotly({
    df <- metricas_classe_consolidadas()
    req(nrow(df) > 0)
    df <- df %>% mutate(Erro_Comissao = 1 - UA)
    # Acerto (UA) a esquerda, classe no meio, Erro de Comissao (1 - UA) a direita
    grafico_piramide(df, col_acerto = "UA", col_erro = "Erro_Comissao",
                     label_acerto = "Acurácia do Usuário (Acerto)",
                     label_erro = "Erro de Comissão",
                     cor_acerto = "#3d6b64", cor_erro = "#e1ad52")
  })
  
  output$grafico_PA <- renderPlotly({
    df <- metricas_classe_consolidadas()
    req(nrow(df) > 0)
    df <- df %>% mutate(Erro_Omissao = 1 - PA)
    # Acerto (PA) a esquerda, classe no meio, Erro de Omissao (1 - PA) a direita
    grafico_piramide(df, col_acerto = "PA", col_erro = "Erro_Omissao",
                     label_acerto = "Acurácia do Produtor (Acerto)",
                     label_erro = "Erro de Omissão",
                     cor_acerto = "#c79b6f", cor_erro = "#e1ad52")
  })
  
  output$grafico_serie_temporal <- renderPlotly({
    df <- dados_serie_temporal()
    req(nrow(df) > 0)
    
    plot_ly(df, x = ~ano_num, y = ~estimate, color = ~region, type = 'scatter', mode = 'lines+markers') %>%
      layout(xaxis = list(title = "Ano", dtick = 1),
             yaxis = list(title = "Acurácia Global (OA)", tickformat = ".1%"),
             paper_bgcolor = "#181a1b", plot_bgcolor = "#181a1b", font = list(color = "#e2e2e2"),
             legend = list(title = list(text = "Região")))
  })
  
  # Matriz de confusao agregada (usada tanto pelo heatmap quanto pela tabela de
  # metricas por classe, para garantir que os dois SEMPRE mostrem os mesmos numeros).
  # "contagem" = numero estimado de amostras na celula (estimate * n), somado
  # entre as combinacoes de regiao/ano selecionadas.
  matriz_confusao_agregada <- reactive({
    dados_base_confusion() %>%
      filter(class_nome %in% input$filtro_classe, ref_nome %in% input$filtro_classe) %>%
      mutate(contagem = estimate * n) %>%
      group_by(class_nome, ref_nome) %>%
      summarise(estimate = mean(estimate, na.rm = TRUE),
                contagem = sum(contagem, na.rm = TRUE),
                .groups = "drop")
  })
  
  # Versao "em numeros" da tabela de metricas por classe: acertos (diagonal),
  # erro de comissao (classificado como X mas nao e) e erro de omissao
  # (deveria ser X mas foi classificado como outra coisa) -- tudo em numero
  # estimado de amostras, calculado a partir da mesma matriz do heatmap.
  contagem_classe_consolidada <- reactive({
    df <- matriz_confusao_agregada()
    req(nrow(df) > 0)
    
    diagonal <- df %>% filter(class_nome == ref_nome) %>% select(Classe = class_nome, Acertos = contagem)
    total_col <- df %>% group_by(Classe = class_nome) %>% summarise(Total_Classificado = sum(contagem, na.rm = TRUE), .groups = "drop")
    total_row <- df %>% group_by(Classe = ref_nome) %>% summarise(Total_Referencia = sum(contagem, na.rm = TRUE), .groups = "drop")
    
    tibble(Classe = input$filtro_classe) %>%
      left_join(diagonal, by = "Classe") %>%
      left_join(total_col, by = "Classe") %>%
      left_join(total_row, by = "Classe") %>%
      mutate(
        Acertos = coalesce(Acertos, 0),
        Total_Classificado = coalesce(Total_Classificado, 0),
        Total_Referencia = coalesce(Total_Referencia, 0),
        `Erro Comissão` = round(Total_Classificado - Acertos),
        `Erro Omissão` = round(Total_Referencia - Acertos),
        Acertos = round(Acertos)
      ) %>%
      select(Classe, Acertos, `Erro Comissão`, `Erro Omissão`)
  })
  
  # Legenda acima da tabela avisando em qual modo ela esta (acompanha o heatmap)
  output$modo_tabela_label <- renderText({
    if (identical(input$heatmap_modo, "num")) {
      "Modo: Números (amostras estimadas) — igual ao heatmap ao lado."
    } else {
      "Modo: Porcentagem — igual ao heatmap ao lado."
    }
  })
  
  output$heatmap_mc <- renderPlotly({
    df <- matriz_confusao_agregada()
    req(nrow(df) > 0)
    
    modo_pct <- identical(input$heatmap_modo, "pct")
    valor_exibido <- if (modo_pct) df$estimate else df$contagem
    rotulo_texto <- if (modo_pct) percent(df$estimate, 0.1) else comma(round(df$contagem), big.mark = ".")
    titulo_legenda <- if (modo_pct) "Proporção (Acertos)" else "Nº de amostras (Acertos)"
    
    df <- df %>% mutate(
      valor_exibido = valor_exibido,
      rotulo_texto = rotulo_texto,
      fill_valor = ifelse(class_nome == ref_nome, valor_exibido, NA_real_)
    )
    
    g <- ggplot(df, aes(x = ref_nome, y = class_nome, fill = fill_valor)) +
      geom_tile(color = "#121415") +
      geom_text(aes(label = rotulo_texto), color = "white", size = 2.5) +
      # so os acertos (diagonal, class == reference) recebem cor; erros ficam
      # na cor neutra do fundo (na.value), sem "esquentar" o heatmap
      scale_fill_gradient(low = "#202324", high = "#67b99a", na.value = "#202324") +
      # inverte o eixo Y para que a diagonal de acertos va do canto
      # superior-esquerdo ao inferior-direito
      scale_y_discrete(limits = rev) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, color = "white"),
            axis.text.y = element_text(color = "white"),
            text = element_text(color = "white"),
            panel.grid = element_blank()) +
      labs(x = "Referência (campo)", y = "Classificação (MapBiomas)", fill = titulo_legenda)
    
    ggplotly(g) %>% layout(paper_bgcolor = "#181a1b", plot_bgcolor = "#181a1b")
  })
  
  output$tabela_metrics_classe <- renderTable({
    if (identical(input$heatmap_modo, "num")) {
      # mesmo modo do heatmap: numero estimado de amostras
      df <- contagem_classe_consolidada()
      req(nrow(df) > 0)
      df %>% mutate(
        Acertos = comma(Acertos, big.mark = "."),
        `Erro Comissão` = comma(`Erro Comissão`, big.mark = "."),
        `Erro Omissão` = comma(`Erro Omissão`, big.mark = ".")
      )
    } else {
      # mesmo modo do heatmap: porcentagem
      req(metricas_classe_consolidadas())
      metricas_classe_consolidadas() %>%
        mutate(UA = percent(UA, 0.1), PA = percent(PA, 0.1), F1 = percent(F1, 0.1)) %>%
        select(Classe, UA, PA, F1)
    }
  }, class = "table table-dark table-striped")
}

shinyApp(ui, server)

