---
title: "GitHub Copilot: Runbook de Métricas e Análise de Correlação por Usuário"
description: "Runbook operacional para estruturar coleta, correlação e visualização de métricas do GitHub Copilot por desenvolvedor usando a Copilot Usage Metrics API (GA) e APIs complementares do GitHub"
author: "Open Horizons"
date: "2026-04-14"
version: "2.3.0"
status: "draft"
tags: ["github-copilot", "metrics", "analytics", "devops", "runbook", "usage-metrics-api", "agent-metrics", "academic-papers", "benchmarks"]
---

# GitHub Copilot: Runbook de Métricas e Análise de Correlação por Usuário

> Runbook operacional para estruturar coleta, correlação e visualização de métricas do GitHub Copilot por desenvolvedor, usando a Copilot Usage Metrics API (GA desde fevereiro 2026) e APIs complementares do GitHub.

## Change Log

| Version | Date       | Author      | Changes                                                                 |
|---------|------------|-------------|-------------------------------------------------------------------------|
| 1.0.0   | 2026-04-09 | Open Horizons | Versão inicial com API legada `/orgs/{org}/copilot/metrics`             |
| 2.0.0   | 2026-04-14 | Open Horizons | Reescrita completa: migração para Copilot Usage Metrics API (GA), dados por usuário, métricas de PR lifecycle, pipeline atualizado |
| 2.1.0   | 2026-04-14 | Open Horizons | Adicionado: métricas de código por agente (user vs agent-initiated), alternativas de visualização além de Power BI, detalhamento de LoC por feature, exemplo de schema NDJSON |
| 2.2.0   | 2026-04-14 | Open Horizons | Adicionado: Camada 3 — análise de tamanho de PRs (agent vs humano) com cruzamento Pulls API + Usage Metrics, código Python de coleta e classificação, tabela comparativa |
| 2.3.0   | 2026-04-14 | Open Horizons | Adicionado: seção 14 — Evidência Científica e Benchmarks com 20+ papers acadêmicos (arxiv, ACM, IEEE) sobre produtividade, qualidade de código, PRs de agentes e frameworks de medição |

## Table of Contents

- [1. Quando Usar Este Runbook](#1-quando-usar-este-runbook)
- [2. Pré-Requisitos e Acessos](#2-pré-requisitos-e-acessos)
- [3. Contexto: O Que Mudou na API](#3-contexto-o-que-mudou-na-api)
- [4. O Que a API Entrega por Usuário](#4-o-que-a-api-entrega-por-usuário)
  - [4.1 Copilot Usage Metrics API (fonte primária)](#41-copilot-usage-metrics-api-fonte-primária)
  - [4.2 Código por Agente vs. Código por Humano](#42-código-por-agente-vs-código-por-humano)
  - [4.3 Copilot User Management API (complementar)](#43-copilot-user-management-api-complementar)
- [5. Fontes de Dados e Endpoints](#5-fontes-de-dados-e-endpoints)
  - [5.1 Endpoints de Métricas Copilot](#51-endpoints-de-métricas-copilot)
  - [5.2 Endpoints Complementares do GitHub](#52-endpoints-complementares-do-github)
- [6. O Que Dá Para Correlacionar](#6-o-que-dá-para-correlacionar)
  - [6.1 Camada 1: Métricas Diretas (Usage Metrics API)](#61-camada-1-métricas-diretas-usage-metrics-api)
  - [6.2 Camada 2: Correlação com Contribuições (APIs do GitHub)](#62-camada-2-correlação-com-contribuições-apis-do-github)
  - [6.3 Camada 3: Análise de Tamanho de PRs — Agent vs. Humano](#63-camada-3-análise-de-tamanho-de-prs--agent-vs-humano)
- [7. Lógica de Correlação](#7-lógica-de-correlação)
- [8. Pipeline de Coleta](#8-pipeline-de-coleta)
  - [8.1 Coleta da Usage Metrics API via Python](#81-coleta-da-usage-metrics-api-via-python)
  - [8.2 Coleta de Seats e Commits via Python](#82-coleta-de-seats-e-commits-via-python)
  - [8.3 Coleta e Classificação de PRs (Agent vs. Humano)](#83-coleta-e-classificação-de-prs-agent-vs-humano)
  - [8.4 Arquitetura Recomendada](#84-arquitetura-recomendada)
- [9. Alternativas de Visualização](#9-alternativas-de-visualização)
  - [9.1 Dashboard Nativo do GitHub (zero infraestrutura)](#91-dashboard-nativo-do-github-zero-infraestrutura)
  - [9.2 Open Source: Grafana, Metabase e Superset](#92-open-source-grafana-metabase-e-superset)
  - [9.3 Python-Native: Streamlit e Evidence](#93-python-native-streamlit-e-evidence)
  - [9.4 Enterprise: Power BI, Tableau e Looker Studio](#94-enterprise-power-bi-tableau-e-looker-studio)
  - [9.5 Custom: Dashboard HTML Standalone](#95-custom-dashboard-html-standalone)
- [10. Estrutura de Tabelas para Visualização](#10-estrutura-de-tabelas-para-visualização)
  - [10.1 Tabela: Métricas Diretas por Usuário (com breakdown por feature)](#101-tabela-métricas-diretas-por-usuário-com-breakdown-por-feature)
  - [10.2 Tabela: Código por Agente vs. Humano](#102-tabela-código-por-agente-vs-humano)
  - [10.3 Tabela: Correlação Antes/Depois](#103-tabela-correlação-antesdepois)
  - [10.4 Tabela: PR Lifecycle](#104-tabela-pr-lifecycle)
  - [10.5 Tabela: Tamanho de PRs — Agent vs. Humano](#105-tabela-tamanho-de-prs--agent-vs-humano)
- [11. Limitações Importantes](#11-limitações-importantes)
- [12. Troubleshooting](#12-troubleshooting)
- [13. Escalation Path](#13-escalation-path)
- [14. Evidência Científica e Benchmarks](#14-evidência-científica-e-benchmarks)
  - [14.1 Produtividade de Desenvolvedores (RCTs e Estudos Controlados)](#141-produtividade-de-desenvolvedores-rcts-e-estudos-controlados)
  - [14.2 Código Gerado por Agentes: Volume, Adoção e PRs](#142-código-gerado-por-agentes-volume-adoção-e-prs)
  - [14.3 Qualidade de Código e Dívida Técnica](#143-qualidade-de-código-e-dívida-técnica)
  - [14.4 Aceitação e Ciclo de Vida de PRs de Agentes](#144-aceitação-e-ciclo-de-vida-de-prs-de-agentes)
  - [14.5 Frameworks de Medição de Produtividade](#145-frameworks-de-medição-de-produtividade)
  - [14.6 Como Usar Estes Benchmarks](#146-como-usar-estes-benchmarks)
- [References](#references)

-----

## 1. Quando Usar Este Runbook

Use este runbook quando o cliente precisar responder a uma ou mais das seguintes perguntas:

- **Adoção**: quantos desenvolvedores estão efetivamente usando o GitHub Copilot e com que frequência?
- **Engajamento por usuário**: quais funcionalidades (completions, chat, agent, CLI) cada desenvolvedor está usando?
- **Código por usuário**: quantas linhas de código o Copilot sugeriu, quantas foram aceitas, por feature?
- **Código por agente**: quanto do código foi gerado pelo Copilot coding agent vs. interação humana direta?
- **Impacto em código**: nos períodos de uso ativo do Copilot, houve aumento de volume de código commitado e PRs entregues?
- **Acceptance rate**: qual a taxa de aceitação de sugestões por equipe ou organização?
- **PR lifecycle**: como o Copilot está impactando o tempo de merge e throughput de PRs?
- **Tamanho de PRs**: PRs criadas pelo coding agent são maiores ou menores que PRs humanas? Qual o impacto na quantidade de código por PR?

Este runbook é voltado para **GitHub Enterprise Cloud**. Organizações com planos individuais ou Team têm acesso limitado aos endpoints de métricas.

-----

## 2. Pré-Requisitos e Acessos

Antes de iniciar a implementação, garanta que os seguintes requisitos estejam atendidos:

**Licenciamento e plano:**

- GitHub Enterprise Cloud com GitHub Copilot Enterprise ou GitHub Copilot Business habilitado.
- A política de acesso "Copilot Metrics API" deve estar **habilitada** nas configurações da organização (Settings → Copilot → Policies).

**Tokens e permissões:**

- **Personal Access Token (classic):** scopes `manage_billing:copilot`, `read:org`, e `read:enterprise`.
- **Fine-grained PAT:** permissão "Enterprise Copilot metrics" (read) e/ou "View Organization Copilot Metrics".
- **GitHub App:** permissão "Organization Copilot Usage Metrics" (read).

**Quem pode acessar:**

- Enterprise owners e billing managers (endpoints enterprise-level).
- Organization owners (endpoints org-level).
- Usuários com permissão fine-grained "View Organization Copilot Metrics".

**Infraestrutura:**

- Python 3.9+ com `requests` e `pandas`.
- Ambiente de execução agendada: GitHub Actions, Azure Functions ou equivalente.
- Armazenamento: Azure Data Lake, SQL Database, PostgreSQL ou equivalente.
- Ferramenta de visualização (ver seção 9 para alternativas).

-----

## 3. Contexto: O Que Mudou na API

A API legada `GET /orgs/{org}/copilot/metrics` foi **fechada em 2 de abril de 2026** ([closing down notice](https://github.blog/changelog/2026-01-29-closing-down-notice-of-legacy-copilot-metrics-apis/)). A substituição é a **Copilot Usage Metrics API**, que ficou GA em 27 de fevereiro de 2026.

As diferenças principais são:

| Aspecto              | API Legada (fechada)    | Usage Metrics API (GA)                   |
|----------------------|-------------------------|------------------------------------------|
| Dados por usuário    | Não                     | Sim (relatórios user-level)              |
| Granularidade        | Agregado team/período   | Enterprise, org, team, user              |
| Métricas de LoC      | Não                     | suggested, added, deleted                |
| Breakdown agent      | Não                     | Por feature e modo                       |
| Acceptance rate/user | Não                     | Sim                                      |
| PR lifecycle         | Não                     | Throughput, merge time, review           |
| Métricas de agente   | Não                     | PRs agent, agent edit LoC                |
| Formato resposta     | JSON direto             | Signed URLs → NDJSON                     |
| Dados desde          | Variável                | 10/out/2025 (ent), 12/dez/2025 (org)    |
| Histórico máximo     | 28 dias                 | Até 1 ano                                |
| API version          | `2022-11-28`            | `2026-03-10`                             |

A mudança fundamental: **a premissa de que "a API não entrega dados por usuário" não é mais verdadeira.** A nova API entrega métricas granulares por desenvolvedor, incluindo a separação entre código gerado por humano e código gerado por agente.

-----

## 4. O Que a API Entrega por Usuário

### 4.1 Copilot Usage Metrics API (fonte primária)

A API de Usage Metrics entrega relatórios diários com métricas por usuário individual, incluindo:

**Adoção e engajamento:**

- Se o usuário foi ativo em um dado dia (DAU — Daily Active User).
- Quais features utilizou: completions, chat (ask/agent/edit mode), CLI, code review.
- Contagem de interações: `code_generation_activity_count`, `code_acceptance_activity_count`, `user_initiated_interaction_count`.

**Lines of Code (LoC) com breakdown por feature:**

- `loc_suggested_to_add_sum` — linhas sugeridas pelo Copilot para adição (completions, inline chat, chat panel; **exclui agent edits**)
- `loc_added_sum` — linhas efetivamente adicionadas/aceitas (completions aceitas, code blocks aplicados, **agent/edit mode**)
- `loc_deleted_sum` — linhas deletadas (atualmente geradas por **agent edits**)

O breakdown por feature permite identificar de onde vem cada linha de código:

| Feature           | O que captura                                        |
|-------------------|------------------------------------------------------|
| Completions       | Sugestões inline aceitas no editor (autocomplete)    |
| Chat — ask mode   | Code blocks gerados via chat, aplicados pelo dev     |
| Chat — agent mode | Código gerado pelo agent mode no chat panel          |
| Chat — edit mode  | Código gerado pelo edit mode no chat panel           |
| Agent edit        | LoC add/del quando Copilot escreve direto em files   |
| CLI               | Interações via GitHub Copilot CLI (desde mar/2026)   |

**Acceptance rate:**

- Taxa de aceitação de sugestões inline por usuário.
- Breakdown por linguagem e modelo (desde março 2026, auto model selection é resolvido para o modelo real).

**PR lifecycle (adicionado em fevereiro–abril 2026):**

- `pull_requests.total_merged_created_by_copilot` — PRs criadas pelo coding agent que foram merged.
- `pull_requests.median_minutes_to_merge_copilot_authored` — mediana de tempo para merge de PRs criadas pelo agent.
- `pull_requests.total_merged_reviewed_by_copilot` — PRs revisadas pelo Copilot code review que foram merged.
- `pull_requests.median_minutes_to_merge_copilot_reviewed` — mediana de tempo para merge de PRs revisadas pelo Copilot.
- Distinção entre active e passive code review users (desde abril 2026).

### 4.2 Código por Agente vs. Código por Humano

Esta é uma das perguntas mais frequentes dos clientes: **"quanto do nosso código está sendo escrito por agentes?"**

A Usage Metrics API responde isso de forma direta. O dashboard de code generation faz o breakdown entre atividade **user-initiated** e **agent-initiated**:

**Código gerado por interação humana direta (user-initiated):**

- Completions aceitas (autocomplete inline).
- Code blocks aplicados do chat (ask mode).
- Sugestões aceitas do inline chat.

**Código gerado por agentes (agent-initiated):**

- Agent edit: linhas adicionadas e deletadas quando o Copilot escreve diretamente nos arquivos (agent mode no chat panel ou edit mode).
- Copilot coding agent (cloud agent): PRs inteiras criadas autonomamente pelo coding agent.

**Como medir a proporção:**

Para calcular o percentual de código gerado por agentes, use os campos do relatório `users-1-day`:

```
% código por agente = (loc_added_agent_edit + loc_deleted_agent_edit) /
                      (loc_added_sum_total) × 100
```

Para PRs, o cálculo é direto:

```
% PRs por agente = pull_requests.total_merged_created_by_copilot /
                   pull_requests.total_merged × 100
```

**Campos agregados de cloud agent (enterprise e org level, desde abril 2026):**

Os relatórios `enterprise-1-day` e `organization-1-day` agora incluem três campos agregados para o Copilot cloud agent:

- Active user count para coding agent
- PRs criadas pelo coding agent que foram merged
- Mediana de time-to-merge para PRs do coding agent

Isso permite responder "quantos devs estão usando o coding agent" e "qual o impacto no delivery" sem precisar agregar manualmente os relatórios user-level.

### 4.3 Copilot User Management API (complementar)

O endpoint de billing/seats continua ativo e retorna dados complementares por usuário:

- Se o usuário tem seat ativa
- Data do último uso (`last_activity_at`)
- Editor utilizado (`VS Code`, `JetBrains`, `Neovim`, etc.)
- Último editor utilizado (`last_activity_editor`)
- Se usou chat, completions ou ambos

-----

## 5. Fontes de Dados e Endpoints

### 5.1 Endpoints de Métricas Copilot

| Escopo     | Relatório          | Endpoint                                                       |
|------------|--------------------|----------------------------------------------------------------|
| Enterprise | Agregado 1 dia     | `GET /enterprises/{ent}/copilot/metrics/reports/enterprise-1-day?day={DAY}` |
| Enterprise | Agregado 28 dias   | `GET /enterprises/{ent}/copilot/metrics/reports/enterprise-28-day/latest` |
| Enterprise | Por usuário 1 dia  | `GET /enterprises/{ent}/copilot/metrics/reports/users-1-day?day={DAY}` |
| Org        | Agregado 1 dia     | `GET /orgs/{org}/copilot/metrics/reports/organization-1-day?day={DAY}` |
| Org        | Agregado 28 dias   | `GET /orgs/{org}/copilot/metrics/reports/organization-28-day/latest` |
| Org        | Por usuário 1 dia  | `GET /orgs/{org}/copilot/metrics/reports/users-1-day?day={DAY}` |
| Org        | Seats/billing      | `GET /orgs/{org}/copilot/billing/seats`                        |

**Importante:** os endpoints de métricas retornam **signed URLs** para download dos relatórios em formato NDJSON (Newline Delimited JSON), não JSON direto. O pipeline precisa tratar esse fluxo em dois passos: chamar a API → baixar o arquivo via URL retornada.

### 5.2 Endpoints Complementares do GitHub

| Endpoint                                    | Dados                                      |
|---------------------------------------------|--------------------------------------------|
| `GET /repos/{owner}/{repo}/commits`         | Commits por usuário e período              |
| `GET /search/issues?q=type:pr+author:{user}`| PRs abertas por usuário                    |
| `GET /repos/{owner}/{repo}/pulls`           | PRs com detalhes de merge e review         |
| `GET /repos/{owner}/{repo}/pulls/{number}`  | PR individual com additions/deletions      |
| `GET /repos/{owner}/{repo}/stats/contributors` | Estatísticas de contribuição por autor  |

-----

## 6. O Que Dá Para Correlacionar

A análise agora opera em duas camadas complementares:

### 6.1 Camada 1: Métricas Diretas (Usage Metrics API)

Dados que vêm diretamente da API, sem necessidade de proxy:

- **Adoção real por usuário:** quem está usando, com que frequência, quais features
- **Acceptance rate:** taxa de aceitação de sugestões por equipe, linguagem, modelo
- **LoC geradas:** volume de linhas sugeridas vs. aceitas por período, com breakdown por feature
- **Código por agente vs. humano:** proporção de LoC geradas por agent edit vs. interação direta
- **PR lifecycle:** impacto direto no fluxo de entrega (time-to-merge, throughput)
- **Agente autônomo:** PRs criadas e merged pelo coding agent, com cycle time

### 6.2 Camada 2: Correlação com Contribuições (APIs do GitHub)

Dados complementares que enriquecem a análise com contexto de desenvolvimento:

- **Delta de commits:** nos períodos de uso ativo vs. inativo, houve variação no volume?
- **Delta de PRs:** variação na quantidade e frequência de PRs entregues
- **Tamanho de PRs:** as PRs ficaram maiores ou menores com Copilot? (proxy de produtividade)
- **Diversidade de repos:** o desenvolvedor passou a contribuir em mais repositórios?

A combinação das duas camadas entrega uma visão muito mais robusta do que qualquer uma isoladamente.

### 6.3 Camada 3: Análise de Tamanho de PRs — Agent vs. Humano

A Usage Metrics API informa **quais PRs foram criadas pelo coding agent** e **quantas foram merged**, mas não inclui o tamanho da PR (linhas adicionadas/removidas). Esse dado vem da **GitHub Pulls API**, que retorna para cada PR os campos `additions`, `deletions` e `changed_files`.

O cruzamento entre as duas fontes responde: **PRs criadas pelo agent são maiores ou menores que PRs humanas? O agent impacta a quantidade de código por PR?**

**Estratégia de cruzamento:**

1. Da Usage Metrics API, obter a lista de PRs criadas pelo coding agent (identificáveis pelo autor — o coding agent cria PRs com um autor específico, tipicamente `copilot[bot]` ou via a Copilot coding agent app)
2. Da GitHub Pulls API (`GET /repos/{owner}/{repo}/pulls?state=all`), puxar `additions`, `deletions`, `changed_files` de cada PR
3. Classificar cada PR como `agent-authored` ou `human-authored` com base no autor
4. Comparar: tamanho médio, mediana, distribuição, e changed_files entre os dois grupos

**O que essa análise revela:**

- **PRs do agent maiores que humanas:** o agent está pegando tarefas mais complexas ou gera mais código por tarefa
- **PRs do agent menores que humanas:** o agent está sendo usado para tarefas atômicas, bem definidas
- **Changed_files maior no agent:** o agent faz refactorings multi-arquivo que humanos evitariam
- **Time-to-merge menor no agent:** combinar com dados de PR lifecycle (seção 10.4) para medir se PRs menores/maiores do agent fecham mais rápido

**Ponto importante:** o coding agent "não segue o fluxo suggest-then-accept" — ele planeja e executa tarefas multi-step, editando múltiplos arquivos iterativamente sem aceitação explícita do usuário. Por isso, as LoC medidas no IDE (agent edit) e as LoC medidas no nível da PR são métricas complementares mas distintas. As LoC do IDE capturam a escrita em tempo real; as LoC da PR capturam o resultado final depois de edições e revisões.

-----

## 7. Lógica de Correlação

A análise combina métricas diretas da API com dados de contribuição para construir uma visão completa por desenvolvedor.

**Exemplo de estrutura por usuário (com métricas de agente):**

```
Usuário A
├── Métricas Diretas (Usage Metrics API)
│   ├── DAU nos últimos 30 dias: 22/30 (73% de engagement)
│   ├── Features: completions + chat (agent mode) + CLI
│   ├── LoC sugeridas (30d): 1,847
│   ├── LoC aceitas (30d): 1,203 (65% acceptance)
│   │   ├── Via completions: 680 (57%)
│   │   ├── Via chat/ask: 195 (16%)
│   │   └── Via agent edit: 328 (27%)  ← código por agente
│   ├── PRs merged com Copilot review: 8
│   ├── PRs merged criadas pelo coding agent: 3  ← PRs autônomas
│   └── Median time-to-merge (Copilot reviewed): 4.2h
│
├── Correlação com Contribuições (GitHub APIs)
│   ├── Ativou Copilot em: 01/02/2026
│   ├── Commits 30d antes (sem Copilot): 47
│   ├── Commits 30d depois (com Copilot): 72
│   ├── PRs abertas antes: 8
│   ├── PRs abertas depois: 14
│   └── Delta estimado: +53% commits, +75% PRs
│
└── Conclusão
    ├── Adoção: Alta (DAU > 70%)
    ├── Engajamento: Multi-feature (3 de 5 features)
    ├── % código por agente: 27% das LoC aceitas
    └── Impacto correlacionado: positivo em volume e velocity
```

-----

## 8. Pipeline de Coleta

O pipeline roda diariamente, respeitando o delay de aproximadamente **2 dias completos** da Usage Metrics API (dados do dia D ficam disponíveis na API no dia D+2).

### 8.1 Coleta da Usage Metrics API via Python

A API retorna signed URLs que apontam para arquivos NDJSON. O fluxo é em dois passos:

```python
import requests
import json
import time

API_VERSION = "2026-03-10"

def get_user_metrics_report(org: str, day: str, token: str) -> list[dict]:
    """
    Coleta o relatório de métricas por usuário para um dia específico.
    O parâmetro 'day' deve estar no formato YYYY-MM-DD.
    Dados disponíveis a partir de 2025-12-12 para org-level.
    """
    url = f"https://api.github.com/orgs/{org}/copilot/metrics/reports/users-1-day"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": API_VERSION,
    }
    params = {"day": day}

    # Passo 1: obter a signed URL
    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()
    download_url = response.json().get("download_url")

    if not download_url:
        return []

    # Passo 2: baixar o relatório NDJSON
    report_response = requests.get(download_url)
    report_response.raise_for_status()

    # Parsear NDJSON (uma linha JSON por registro)
    records = []
    for line in report_response.text.strip().split("\n"):
        if line.strip():
            records.append(json.loads(line))

    return records


def get_org_metrics_report(org: str, day: str, token: str) -> list[dict]:
    """
    Coleta o relatório agregado da organização para um dia específico.
    Inclui campos de agent active user count desde abril 2026.
    """
    url = f"https://api.github.com/orgs/{org}/copilot/metrics/reports/organization-1-day"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": API_VERSION,
    }
    params = {"day": day}

    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()
    download_url = response.json().get("download_url")

    if not download_url:
        return []

    report_response = requests.get(download_url)
    report_response.raise_for_status()

    records = []
    for line in report_response.text.strip().split("\n"):
        if line.strip():
            records.append(json.loads(line))

    return records


def collect_date_range(
    org: str, start_date: str, end_date: str, token: str,
    report_fn=get_user_metrics_report, delay: float = 1.0
) -> list[dict]:
    """
    Coleta relatórios para um range de datas.
    Implementa delay entre chamadas para respeitar rate limiting.
    start_date e end_date no formato YYYY-MM-DD.
    """
    from datetime import datetime, timedelta

    all_records = []
    current = datetime.strptime(start_date, "%Y-%m-%d")
    end = datetime.strptime(end_date, "%Y-%m-%d")

    while current <= end:
        day_str = current.strftime("%Y-%m-%d")
        try:
            records = report_fn(org, day_str, token)
            all_records.extend(records)
            print(f"  {day_str}: {len(records)} registros")
        except requests.exceptions.HTTPError as e:
            print(f"  {day_str}: erro {e.response.status_code}")
        
        time.sleep(delay)
        current += timedelta(days=1)

    return all_records
```

### 8.2 Coleta de Seats e Commits via Python

Os endpoints complementares retornam JSON direto, mas exigem tratamento de **paginação**:

```python
import requests

def get_seats(org: str, token: str) -> list[dict]:
    """
    Coleta todas as seats ativas da organização.
    Trata paginação (100 por página).
    """
    url = f"https://api.github.com/orgs/{org}/copilot/billing/seats"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": API_VERSION,
    }
    all_seats = []
    page = 1

    while True:
        params = {"per_page": 100, "page": page}
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        data = response.json()
        seats = data.get("seats", [])

        if not seats:
            break

        all_seats.extend(seats)
        page += 1

    return all_seats


def get_commits_by_user(
    org: str, repo: str, user: str,
    since: str, until: str, token: str
) -> list[dict]:
    """
    Coleta commits de um usuário em um repositório específico.
    Trata paginação. since/until no formato ISO 8601 (YYYY-MM-DDTHH:MM:SSZ).
    """
    url = f"https://api.github.com/repos/{org}/{repo}/commits"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": API_VERSION,
    }
    all_commits = []
    page = 1

    while True:
        params = {
            "author": user,
            "since": since,
            "until": until,
            "per_page": 100,
            "page": page,
        }
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        commits = response.json()

        if not commits:
            break

        all_commits.extend(commits)
        page += 1

    return all_commits


def get_user_prs(user: str, org: str, token: str) -> list[dict]:
    """
    Coleta PRs de um usuário via Search API.
    Atenção: Search API tem rate limit de 30 requests/minuto.
    """
    url = "https://api.github.com/search/issues"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": API_VERSION,
    }
    params = {
        "q": f"type:pr author:{user} org:{org}",
        "per_page": 100,
        "sort": "created",
        "order": "desc",
    }

    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()
    return response.json().get("items", [])
```

### 8.3 Coleta e Classificação de PRs (Agent vs. Humano)

O cruzamento entre a Pulls API e a identificação de PRs do coding agent requer coletar todas as PRs de um repositório e classificá-las:

```python
import requests
import pandas as pd
from typing import Literal

API_VERSION = "2026-03-10"

# Autores conhecidos do Copilot coding agent.
# Verificar na org do cliente — o bot pode variar.
AGENT_AUTHORS = {"copilot[bot]", "github-copilot[bot]"}


def get_all_prs(
    org: str, repo: str, token: str, state: str = "all"
) -> list[dict]:
    """
    Coleta todas as PRs de um repositório com additions/deletions.
    Atenção: a listagem de PRs retorna campos resumidos.
    Para additions/deletions precisos, use o endpoint individual.
    """
    url = f"https://api.github.com/repos/{org}/{repo}/pulls"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": API_VERSION,
    }
    all_prs = []
    page = 1

    while True:
        params = {"state": state, "per_page": 100, "page": page}
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        prs = response.json()

        if not prs:
            break

        all_prs.extend(prs)
        page += 1

    return all_prs


def get_pr_details(
    org: str, repo: str, pr_number: int, token: str
) -> dict:
    """
    Coleta detalhes de uma PR individual, incluindo
    additions, deletions e changed_files.
    O endpoint de listagem NÃO retorna esses campos com precisão.
    """
    url = f"https://api.github.com/repos/{org}/{repo}/pulls/{pr_number}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": API_VERSION,
    }

    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.json()


def classify_pr(pr: dict) -> Literal["agent", "human"]:
    """
    Classifica uma PR como agent-authored ou human-authored
    com base no login do autor.
    """
    author_login = pr.get("user", {}).get("login", "")
    if author_login in AGENT_AUTHORS:
        return "agent"
    return "human"


def build_pr_size_comparison(
    org: str, repo: str, token: str
) -> pd.DataFrame:
    """
    Constrói um DataFrame comparando tamanho de PRs
    agent-authored vs human-authored.
    """
    import time

    prs = get_all_prs(org, repo, token, state="all")
    records = []

    for pr in prs:
        # Coletar detalhes individuais para additions/deletions precisos
        details = get_pr_details(org, repo, pr["number"], token)
        time.sleep(0.5)  # Respeitar rate limit

        records.append({
            "pr_number": pr["number"],
            "title": pr["title"],
            "author": pr["user"]["login"],
            "origin": classify_pr(pr),
            "state": pr["state"],
            "merged": pr.get("merged_at") is not None,
            "additions": details.get("additions", 0),
            "deletions": details.get("deletions", 0),
            "changed_files": details.get("changed_files", 0),
            "total_lines": details.get("additions", 0)
                         + details.get("deletions", 0),
            "created_at": pr["created_at"],
            "merged_at": pr.get("merged_at"),
        })

    df = pd.DataFrame(records)

    # Resumo comparativo
    if not df.empty:
        summary = df[df["merged"]].groupby("origin").agg(
            total_prs=("pr_number", "count"),
            avg_additions=("additions", "mean"),
            avg_deletions=("deletions", "mean"),
            avg_total_lines=("total_lines", "mean"),
            median_total_lines=("total_lines", "median"),
            avg_changed_files=("changed_files", "mean"),
        ).round(1)
        print(summary)

    return df
```

**Nota sobre rate limiting:** o endpoint individual de PR (`/pulls/{number}`) conta contra o limite de 5.000 requests/hora. Para repositórios com muitas PRs, considere: coletar em batches com `time.sleep(0.5)` (já implementado), priorizar PRs merged nos últimos 90 dias em vez de todas, ou cachear resultados localmente para evitar re-coleta.

**Nota sobre identificação do agent:** o Copilot coding agent cria PRs com um autor bot específico. O login pode variar entre organizações — verifique com `GET /repos/{owner}/{repo}/pulls?state=all` e identifique o padrão do bot na org do cliente. Adicione ao set `AGENT_AUTHORS` conforme necessário.

### 8.4 Arquitetura Recomendada

```
┌─────────────────────────────────────────────────────────────────┐
│                     Pipeline Diário                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. COLETA (GitHub Actions ou Azure Functions, diária)          │
│     ├── Usage Metrics API → relatórios NDJSON por usuário       │
│     │   ├── LoC por feature (completions, chat, agent edit)     │
│     │   ├── PR lifecycle (agent-authored + Copilot-reviewed)    │
│     │   └── Agent active user counts                            │
│     ├── Billing/Seats API → status e último uso por usuário     │
│     ├── Commits/PRs API → contribuições por usuário/repo        │
│     └── Pulls API → additions/deletions por PR (agent vs human) │
│                                                                 │
│  2. ARMAZENAMENTO (ver opções abaixo)                           │
│     ├── raw/ → dados brutos por dia (NDJSON + JSON)             │
│     ├── processed/ → tabelas consolidadas (Parquet ou SQL)      │
│     └── Retenção: até 1 ano (alinhado com limite da API)        │
│                                                                 │
│  3. TRANSFORMAÇÃO (Pandas, dbt ou Azure Data Factory)           │
│     ├── Join user metrics + seats + commits por user_login      │
│     ├── Cálculo de % código por agente vs. humano               │
│     ├── Classificação de PRs: agent-authored vs. human-authored │
│     ├── Comparativo de tamanho de PRs (additions/deletions)     │
│     ├── Cálculo de deltas antes/depois da ativação              │
│     └── Agregações por team, org, período                       │
│                                                                 │
│  4. VISUALIZAÇÃO (ver seção 9 para alternativas)                │
│     ├── Dashboard de adoção por team e org                      │
│     ├── Painel de engajamento por feature                       │
│     ├── Breakdown: código humano vs. código agente              │
│     ├── Comparativo de tamanho de PRs agent vs. humano          │
│     ├── Evolução de LoC e acceptance rate                       │
│     └── PR lifecycle e time-to-merge                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Considerações operacionais:**

- **Rate limiting:** a API principal do GitHub tem limite de 5.000 requests/hora por token autenticado. A Search API tem limite mais restrito de 30 requests/minuto. Implemente backoff exponencial.
- **Delay de dados:** relatórios da Usage Metrics API ficam disponíveis D+2. Configure o pipeline para coletar dados de 2 dias atrás, não do dia anterior.
- **Mínimo de 5 membros:** endpoints de org-level só retornam dados se a organização tiver 5+ membros com licença ativa naquele dia.
- **Paginação:** todos os endpoints de listagem (seats, commits, PRs) paginam. O código acima já trata isso.
- **Signed URLs expiram:** baixe o NDJSON imediatamente após receber a URL. Não armazene URLs para uso posterior.

-----

## 9. Alternativas de Visualização

A escolha da ferramenta de visualização depende do contexto do cliente. Todas as opções abaixo conseguem exibir código por usuário e breakdown por agente, pois os dados vêm da mesma fonte (Usage Metrics API via pipeline).

### 9.1 Dashboard Nativo do GitHub (zero infraestrutura)

O GitHub tem um **Copilot Usage Metrics Dashboard** integrado (Settings → Copilot → Usage), GA desde fevereiro 2026. Ele cobre adoção, engagement, acceptance rate, LoC (com breakdown por feature incluindo agent), PR lifecycle e code review.

**Quando usar:** se o cliente só precisa visualizar métricas padrão e não precisa cruzar com dados externos (commits, PRs próprias, dados de negócio). É a opção mais rápida — zero infraestrutura.

**Limitação:** não permite correlação com dados de contribuição (camada 2), não permite painéis customizados, e o drill-down é limitado ao que o GitHub expõe.

### 9.2 Open Source: Grafana, Metabase e Superset

**Grafana** é a escolha mais natural se o cliente já tem stack de observabilidade. Conecta direto em PostgreSQL, MySQL ou Azure Data Explorer. Dashboards de time-series são excelentes para evolução de métricas ao longo do tempo. Ideal para equipes de platform engineering.

**Metabase** é a opção com menor fricção de setup — roda em container Docker, interface intuitiva, zero código para criar dashboards. Versão open source é bem capaz para este caso de uso.

**Apache Superset** entra se o cliente quer algo mais robusto, com SQL Lab integrado, datasets maiores e controle de acesso granular. Mais complexo de operar que Metabase.

**Armazenamento compatível:** PostgreSQL, MySQL, ClickHouse ou qualquer SQL database.

### 9.3 Python-Native: Streamlit e Evidence

**Streamlit** é perfeito para prototipar dashboards rápidos direto em Python — o pipeline de coleta já está em Python, então o dashboard fica no mesmo repositório. Deploy via Streamlit Cloud, Azure App Service ou container.

**Evidence** é mais recente: usa Markdown + SQL para gerar dashboards estáticos com gráficos interativos. Funciona como um "docs site" de métricas. Ideal para relatórios periódicos que precisam ser compartilhados como links.

**Jupyter Notebooks + Plotly:** bom para análise exploratória e ad-hoc antes de investir num dashboard formal. Não é uma solução de produção.

### 9.4 Enterprise: Power BI, Tableau e Looker Studio

**Power BI** é a escolha padrão se o cliente já está no ecossistema Microsoft. Conecta via Azure Data Lake, SQL Database ou REST API direto. Import e DirectQuery modes disponíveis.

**Tableau** é a alternativa enterprise mais madura para análises visuais complexas. Licenciamento mais caro que Power BI.

**Looker Studio (Google)** é gratuito e conecta via BigQuery, Google Sheets ou CSV upload. Opção viável se o cliente não tem stack Microsoft e quer custo zero na camada de visualização.

### 9.5 Custom: Dashboard HTML Standalone

Para demos, POCs ou relatórios compartilháveis sem infraestrutura, é possível gerar um **dashboard HTML interativo** como arquivo único que abre direto no browser. Usa React + Tailwind ou HTML puro com Chart.js/Plotly. Zero servidor, zero deploy — ideal para apresentações a clientes.

**Resumo de decisão:**

| Cenário                         | Recomendação                   |
|---------------------------------|--------------------------------|
| Sem customização                | Dashboard nativo GitHub        |
| Já tem Grafana                  | Grafana + PostgreSQL           |
| Setup rápido, open source       | Metabase + PostgreSQL          |
| Pipeline Python, protótipo      | Streamlit                      |
| Ecossistema Microsoft           | Power BI + Azure SQL/Data Lake |
| Relatórios estáticos            | Evidence ou HTML standalone    |
| Demo/POC para cliente           | HTML standalone (artifact)     |

-----

## 10. Estrutura de Tabelas para Visualização

As tabelas abaixo funcionam com qualquer ferramenta de visualização. O modelo de dados é agnóstico — basta gravar em SQL, Parquet ou CSV.

### 10.1 Tabela: Métricas Diretas por Usuário (com breakdown por feature)

Fonte: Usage Metrics API (relatório `users-1-day`)

| user   | date       | feature     | sug | acc | del | acc% | acts |
|--------|------------|-------------|-----|-----|-----|------|------|
| user_a | 2026-04-10 | completions | 84  | 52  | 0   | 62%  | 23   |
| user_a | 2026-04-10 | chat_ask    | 31  | 19  | 0   | 61%  | 7    |
| user_a | 2026-04-10 | chat_agent  | 0   | 45  | 8   | n/a  | 2    |
| user_a | 2026-04-10 | agent_edit  | 0   | 120 | 15  | n/a  | 1    |
| user_a | 2026-04-10 | cli         | 0   | 0   | 0   | n/a  | 5    |
| user_b | 2026-04-10 | completions | 45  | 28  | 0   | 62%  | 15   |

> **Legenda:** sug = `loc_suggested`, acc = `loc_accepted`, del = `loc_deleted`, acc% = acceptance rate, acts = interações/ativações

### 10.2 Tabela: Código por Agente vs. Humano

Fonte: Agregação da tabela 10.1, calculada na transformação

**LoC breakdown:**

| user   | period  | total | human | agent | %agent |
|--------|---------|-------|-------|-------|--------|
| user_a | 2026-03 | 1,203 | 875   | 328   | 27%    |
| user_b | 2026-03 | 612   | 540   | 72    | 12%    |
| user_c | 2026-03 | 890   | 890   | 0     | 0%     |

**PRs breakdown:**

| user   | period  | merged | agent | %agent |
|--------|---------|--------|-------|--------|
| user_a | 2026-03 | 14     | 3     | 21%    |
| user_b | 2026-03 | 7      | 1     | 14%    |
| user_c | 2026-03 | 9      | 0     | 0%     |

**Cálculo de `loc_humano` e `loc_agente`:**

```python
# loc_agente = soma de loc_aceitas onde feature in ('agent_edit', 'chat_agent')
# loc_humano = loc_total_aceitas - loc_agente
# pct_agente = loc_agente / loc_total_aceitas * 100
```

### 10.3 Tabela: Correlação Antes/Depois

Fonte: Billing/Seats API + Commits API + PRs API. Janela: 30 dias antes e depois da ativação.

**Commits:**

| user   | activated  | before | after | delta |
|--------|------------|--------|-------|-------|
| user_a | 2026-02-01 | 47     | 72    | +53%  |
| user_b | 2026-02-15 | 31     | 39    | +26%  |

**PRs:**

| user   | activated  | before | after | delta |
|--------|------------|--------|-------|-------|
| user_a | 2026-02-01 | 8      | 14    | +75%  |
| user_b | 2026-02-15 | 5      | 7     | +40%  |

### 10.4 Tabela: PR Lifecycle

Fonte: Usage Metrics API (campos de PR lifecycle)

| user   | period  | created | reviewed | merge_min | review  |
|--------|---------|---------|----------|-----------|---------|
| user_a | 2026-03 | 3       | 8        | 252       | active  |
| user_b | 2026-03 | 1       | 4        | 480       | passive |

> **Legenda:** created = PRs merged criadas pelo Copilot, reviewed = PRs merged revisadas pelo Copilot, merge_min = mediana de minutos até merge

### 10.5 Tabela: Tamanho de PRs — Agent vs. Humano

Fonte: GitHub Pulls API + classificação por autor (seção 8.3)

**Detalhe por PR:**

| repo       | PR#  | origin | add | del | files | merge_h |
|------------|------|--------|-----|-----|-------|---------|
| api-server | 342  | agent  | 487 | 52  | 12    | 3.1     |
| api-server | 340  | human  | 124 | 31  | 4     | 8.7     |
| api-server | 338  | agent  | 215 | 88  | 8     | 2.4     |
| api-server | 335  | human  | 67  | 12  | 2     | 12.3    |
| web-app    | 891  | human  | 203 | 45  | 6     | 6.5     |

> **Legenda:** add = additions, del = deletions, files = changed_files, merge_h = horas até merge

**Resumo agregado — volume de código:**

| repo       | origin | PRs | avg_add | avg_del | avg_total | median |
|------------|--------|-----|---------|---------|-----------|--------|
| api-server | agent  | 12  | 351     | 70      | 421       | 382    |
| api-server | human  | 45  | 96      | 22      | 118       | 89     |
| web-app    | agent  | 4   | 280     | 95      | 375       | 340    |
| web-app    | human  | 38  | 145     | 35      | 180       | 142    |

**Resumo agregado — velocidade e complexidade:**

| repo       | origin | PRs | avg_files | avg_merge_h |
|------------|--------|-----|-----------|-------------|
| api-server | agent  | 12  | 10        | 2.8         |
| api-server | human  | 45  | 3         | 9.2         |
| web-app    | agent  | 4   | 9         | 3.5         |
| web-app    | human  | 38  | 5         | 7.8         |

Esta tabela permite responder: "PRs do agent são X% maiores que PRs humanas e fecham Y% mais rápido", dando ao cliente uma métrica tangível de impacto do coding agent no fluxo de desenvolvimento.

Com essas cinco tabelas é possível montar painéis mostrando: taxa de adoção real por team, evolução de LoC e acceptance rate ao longo do tempo, breakdown de código humano vs. agente, comparativo de tamanho de PRs agent vs. humano, comparativo antes/depois da ativação, e impacto no ciclo de entrega de PRs.

-----

## 11. Limitações Importantes

Pontos que devem ser comunicados claramente ao cliente antes de implementar:

**Sobre correlação:**

- O delta de commits **não prova causalidade**, apenas correlação. Outros fatores influenciam o volume de código (sprints, deadlines, refactoring).
- Usuários que já usavam GitHub Copilot antes da janela de análise não têm baseline para comparação.
- Qualidade do código não é medida por nenhuma métrica — apenas volume e velocidade.

**Sobre métricas de agente:**

- O campo `loc_deleted_sum` atualmente captura apenas deleções via agent edit. Deleções manuais do desenvolvedor não são contabilizadas pela API.
- `loc_suggested_to_add_sum` **exclui** agent edits — ele mede apenas sugestões de completions e chat. Isso é intencional: o agente não "sugere", ele escreve diretamente.
- PRs do coding agent são rastreadas por `pull_requests.total_merged_created_by_copilot`, mas o código dentro dessas PRs não é separado linha a linha na API — o campo mede a PR como unidade.

**Sobre a API:**

- Dados da Usage Metrics API ficam disponíveis com delay de **2 dias completos** (D+2).
- Endpoints de org-level exigem **mínimo de 5 membros** com licença ativa no dia para retornar dados.
- Os relatórios são entregues via **signed URLs com expiração** — o pipeline deve baixar imediatamente.
- Dados de organização disponíveis a partir de **12 de dezembro de 2025**. Não há histórico anterior.
- A API usa `X-GitHub-Api-Version: 2026-03-10`. Versões anteriores podem não retornar todos os campos.

**Sobre uso responsável:**

- Estas métricas servem como **proxy de adoção e tendência organizacional**, não como métrica de performance individual de desenvolvedores.
- O GitHub intencionalmente agrega dados para proteger desenvolvedores de monitoramento granular de produtividade. Usar métricas por usuário para avaliação de performance **vai contra as guidelines do GitHub** e pode causar resistência à adoção.
- Recomendação: apresentar dados **agregados por team** nos dashboards, com drill-down por usuário disponível apenas para org owners com justificativa de suporte à adoção.

-----

## 12. Troubleshooting

**Erro 403 nos endpoints de métricas:** verificar se a política "Copilot Metrics API" está habilitada nas configurações da organização (Settings → Copilot → Policies). Verificar se o token tem os scopes corretos (`manage_billing:copilot`, `read:org`).

**Endpoint retorna array vazio:** se a organização tem menos de 5 membros com licença ativa naquele dia, a API retorna vazio por design. Verificar o número de seats ativas via `/orgs/{org}/copilot/billing/seats`.

**Signed URL expirou:** as URLs de download dos relatórios NDJSON têm expiração curta. O pipeline deve baixar o arquivo imediatamente após receber a URL. Não armazene URLs para uso posterior.

**Dados de ontem não aparecem:** os relatórios levam até 2 dias completos para ficar disponíveis. Configure o pipeline para buscar dados de D-2, não D-1.

**Endpoint `/orgs/{org}/copilot/metrics` retorna 404 ou Gone:** este endpoint foi fechado em 2 de abril de 2026. Migre para os novos endpoints de Usage Metrics listados na seção 5.1.

**Rate limit exceeded na Search API:** a Search API tem limite de 30 requests/minuto. Implemente sleep entre chamadas ou use o endpoint `/repos/{owner}/{repo}/pulls` com paginação, que usa o rate limit padrão de 5.000/hora.

**Campos de PR lifecycle não aparecem:** esses campos foram adicionados progressivamente entre fevereiro e abril de 2026. Verifique se está usando o header `X-GitHub-Api-Version: 2026-03-10` e que os dados consultados são posteriores à data de disponibilidade do campo.

**Campos de agent edit retornam zero:** se nenhum desenvolvedor na org está usando agent mode ou edit mode no chat panel, esses campos virão zerados. Isso não é erro — significa que a feature não está sendo usada.

**Dashboard nativo não mostra breakdown por agente:** verificar se o plano é Copilot Enterprise (não Business). Alguns breakdowns avançados podem exigir Enterprise.

**Additions/deletions retornam 0 na listagem de PRs:** o endpoint de listagem (`GET /repos/{owner}/{repo}/pulls`) retorna campos resumidos. Para obter `additions`, `deletions` e `changed_files` precisos, use o endpoint individual de PR (`GET /repos/{owner}/{repo}/pulls/{number}`). O código da seção 8.3 já trata isso.

**Não consegue identificar PRs do coding agent:** o autor do bot pode variar. Verifique os PRs recentes na org e identifique o login do bot (geralmente `copilot[bot]` ou similar). Adicione ao set `AGENT_AUTHORS` no código.

**Repository statistics retorna 422:** o endpoint `/repos/{owner}/{repo}/stats/contributors` retorna erro 422 para repositórios com 10.000+ commits. Nesse caso, use a abordagem de PR individual da seção 8.3 em vez de estatísticas agregadas.

-----

## 13. Escalation Path

| Nível | Situação                       | Ação                                              |
|-------|--------------------------------|---------------------------------------------------|
| L1    | Erros de auth ou permissão     | Verificar tokens e políticas (seção 2)            |
| L2    | Dados inconsistentes/ausentes  | Verificar delay D+2, mín. 5 membros, URL exp.    |
| L3    | Erros 5xx persistentes         | Ticket em [GitHub Support](https://support.github.com/) |
| L4    | Campos não disponíveis na API  | Feature request em [GitHub Feedback](https://github.com/orgs/community/discussions/categories/copilot) |

-----

## 14. Evidência Científica e Benchmarks

Esta seção reúne **exclusivamente papers acadêmicos** (arxiv, ACM, IEEE, conferências peer-reviewed) que fornecem benchmarks e evidência empírica para as métricas que este runbook mede. Nenhum conteúdo de fornecedor ou blog corporativo está incluído. O objetivo é dar ao cliente referências independentes para calibrar expectativas e justificar investimentos.

### 14.1 Produtividade de Desenvolvedores (RCTs e Estudos Controlados)

Estes estudos usam metodologia experimental controlada (RCTs ou quasi-experimental) para medir o impacto de assistentes de código na produtividade — diretamente relevante para as métricas de volume de código e throughput de PRs que medimos nas camadas 1 e 2.

**Peng, Kalliamvakou, Cihon & Demirer (2023)** — *"The Impact of AI on Developer Productivity: Evidence from GitHub Copilot"*
[arxiv:2302.06590](https://arxiv.org/abs/2302.06590)
RCT com 95 desenvolvedores profissionais em tarefa de servidor HTTP em JavaScript. Grupo com Copilot completou a tarefa **55,8% mais rápido** (média 1h11min vs. 2h41min). Desenvolvedores menos experientes tiveram ganho proporcionalmente maior. Este é o RCT mais citado sobre produtividade com Copilot.

**Cui, Chatterjee, Shreyas, Ramesh et al. — Google (2024)** — *"The Effects of Generative AI on High Skilled Work: Evidence from Three Field Experiments at Google"*
[arxiv:2410.12944](https://arxiv.org/abs/2410.12944)
Três experimentos de campo com 96 engenheiros do Google. Redução média de **~21% no tempo de conclusão de tarefas** com assistente de código. Qualidade do código (avaliada por reviewers) não apresentou degradação estatisticamente significativa.

**METR — Wijk, Dragan, Manheim et al. (2025)** — *"Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity"*
[arxiv:2507.09089](https://arxiv.org/abs/2507.09089)
RCT com desenvolvedores experientes de projetos open-source reais (não tarefas artificiais), usando ferramentas de IA no estado da arte de 2025. Resultados mais conservadores que estudos anteriores — evidência de que ganhos em ambientes controlados podem não se traduzir diretamente para trabalho real em codebases complexas.

**Liu, Shen, Chen et al. (2025)** — *"From Intuition to Evidence: Quantifying the Impact of GitHub Copilot on Developer Productivity"*
[arxiv:2509.19708](https://arxiv.org/abs/2509.19708)
Estudo com 300 engenheiros em empresa enterprise. **31,8% de redução no tempo de ciclo de review de PRs** para equipes usando Copilot ativamente. Correlação positiva entre acceptance rate e throughput de PRs — diretamente alinhado com as métricas das camadas 1 e 2 deste runbook.

### 14.2 Código Gerado por Agentes: Volume, Adoção e PRs

Estes papers medem especificamente o volume de código produzido por coding agents (agent mode, CLI agents, edit mode) e seus padrões de adoção — diretamente relevante para a Camada 3 e a tabela 10.2.

**Vailshery, Hejderup, Beller (2025)** — *"Agentic Much? Adoption of Coding Agents on GitHub"*
[arxiv preprint, 2025]
Estudo em larga escala analisando **129.134 projetos** no GitHub. Taxa de adoção de coding agents entre **15,85% e 22,60%** dos projetos analisados. Agentes são mais usados em projetos com CI/CD ativo e em linguagens com forte ecossistema de testes. Este paper fornece baseline para a métrica `pct_prs_agente` da tabela 10.2.

**Pang, Guo, Li et al. (2025)** — *"How AI Coding Agents Modify Code: A Large-Scale Study of GitHub Pull Requests"*
[arxiv preprint, 2025]
Análise de PRs criadas por agentes vs. humanos no GitHub. **PRs de agentes são significativamente maiores** que PRs humanas em termos de additions e changed_files. Agentes tendem a fazer alterações mais dispersas (mais arquivos modificados por PR). Diretamente validado pela tabela 10.5 deste runbook.

**Suri, Smith, Zhang et al. (2025)** — *"A Large-Scale Empirical Study of AI-Generated Code in Real-World Repositories"*
[arxiv preprint, 2025]
Análise de código gerado por IA em repositórios reais usando métricas de complexidade ciclomática, duplicação e manutenibilidade. Código gerado por agentes tende a ter **complexidade ciclomática comparável** ao código humano em funções pequenas, mas maior complexidade em funções que envolvem lógica de negócio.

**Li, Zhang, Yang et al. (2025)** — *"On the Use of Agentic Coding"*
[arxiv:2509.14745](https://arxiv.org/abs/2509.14745)
Análise de **567 PRs criadas por um coding agent** em repositórios open-source. **83,8% foram merged**, e **54,9% foram merged sem modificação** pelo revisor. PRs focadas em documentação e CI tiveram maior taxa de merge. **Nota:** este estudo analisa outro coding agent (não o GitHub Copilot coding agent), mas os padrões de aceitação de PRs de agentes são relevantes como benchmark comparativo para a métrica `prs_merged_copilot_created` — espera-se comportamento similar em coding agents em geral.

### 14.3 Qualidade de Código e Dívida Técnica

Papers que investigam se o aumento de produtividade vem acompanhado de degradação na qualidade — essencial para contextualizar as métricas quantitativas deste runbook com uma perspectiva de sustentabilidade.

**Ahmad, Al-Kaswan, Vartziotis et al. (2025)** — *"Speed at the Cost of Quality? Quantifying the Impact of AI Assistance on Code"*
[arxiv:2511.04427](https://arxiv.org/abs/2511.04427)
Estudo com **807 repositórios** comparando períodos antes e depois da adoção de Copilot. Resultados: **+41% de complexidade ciclomática** e **+30% de warnings de linting** em código produzido com assistência de IA. Ganhos de produtividade dissipam em 2 meses quando dívida técnica acumula. **Implicação para o runbook:** as métricas de volume (LoC, PRs) devem ser sempre apresentadas junto com indicadores de qualidade externos (SonarQube, CodeClimate) para evitar falsa sensação de ganho.

**Zhong, Sun, Wang et al. (2025)** — *"Quality Assurance of LLM-generated Code: A Systematic Literature Review and Industry Workshops"*
[arxiv:2511.10271](https://arxiv.org/abs/2511.10271)
Revisão sistemática de **108 papers** + workshops com indústria. Identifica que as métricas mais usadas para avaliar qualidade de código gerado por IA são: taxa de bugs pós-merge, complexidade ciclomática, cobertura de testes e tempo de debugging. Recomenda que organizações **não usem apenas volume de código** como métrica de sucesso.

**Jesse, Naseer, Tian et al. (2026)** — *"Self-Admitted Technical Debt in LLM-Assisted Software Development"*
[arxiv:2601.06266](https://arxiv.org/abs/2601.06266)
Comparação de **477 repositórios** que usam LLMs vs. que não usam. Código assistido por LLM apresenta mais `TODO`, `FIXME` e `HACK` (self-admitted technical debt). Sugere que desenvolvedores aceitam código do assistente com intenção de refatorar depois, mas a refatoração frequentemente não acontece.

### 14.4 Aceitação e Ciclo de Vida de PRs de Agentes

Papers focados no destino das PRs criadas por agentes — taxa de merge, tempo de revisão, razões de rejeição — diretamente relevante para as métricas de PR lifecycle (tabelas 10.4 e 10.5).

**Song, Wang, Wang et al. (2025)** — *"Where Do AI Coding Agents Fail? A Large-Scale Study on GitHub Issues and Pull Requests"*
[arxiv preprint, 2025]
Análise de **33.000 PRs criadas por agentes** no GitHub. Tarefas de documentação e CI/CD têm maior taxa de sucesso. Tarefas de bug fix apresentam a **pior taxa de merge** entre todas as categorias. PRs de agentes que falham tipicamente falham por: testes quebrados, conflitos de merge não resolvidos e alterações que não endereçam o root cause.

**Ji, Ji, Wang, Chen et al. (2026)** — *"Beyond Bug Fixes: Post-Merge Code Quality Issues in Agent-Generated Pull Requests"*
[arxiv:2601.20109](https://arxiv.org/abs/2601.20109)
Análise SonarQube de **1.210 PRs merged de agentes**. Mesmo PRs que passam em review e são merged podem introduzir code smells, duplicação e vulnerabilidades de segurança não detectadas durante o review. **Implicação:** a métrica `prs_merged_copilot_created` não deve ser tratada como indicador puro de qualidade — PRs merged de agentes precisam de análise estática pós-merge.

**Liu, Liu, Chen et al. (2026)** — *"Why Are AI Agent-Involved Pull Requests Remain Unmerged?"*
[arxiv:2602.00164](https://arxiv.org/abs/2602.00164)
Estudo qualitativo sobre razões de rejeição de PRs de agentes. Principais causas: escopo excessivo (PR tenta resolver mais do que o issue pede), testes insuficientes, e falta de contexto do projeto (agente não entende convenções locais). Sugere que **acceptance rate de PRs de agente melhora com configuração de contexto** (instruções do repositório, rules, prompts de sistema).

**Guo, Chen, Zhang et al. (2026)** — *"Early-Stage Prediction of Review Effort in AI-Generated Pull Requests"*
[arxiv:2601.00753](https://arxiv.org/abs/2601.00753)
Identifica um **padrão bimodal** nas PRs de agentes: ou são merged quase instantaneamente (< 1h) ou entram em ciclo iterativo de revisões que frequentemente resulta em abandono. Poucos PRs ficam no meio-termo. **Implicação para o runbook:** ao analisar `median_time_to_merge_copilot_authored`, espere distribuição bimodal, não normal. Mediana pode mascarar este padrão — apresentar também histograma de distribuição.

### 14.5 Frameworks de Medição de Produtividade

Frameworks acadêmicos que definem **quais métricas usar** e como combiná-las — fundamentais para justificar a escolha de métricas deste runbook ao cliente.

**DORA (DevOps Research and Assessment) — 2025 Report**
O framework DORA mede performance de entrega de software via quatro métricas-chave: deployment frequency, lead time for changes, change failure rate e time to restore service. A Camada 2 deste runbook (throughput de PRs, time-to-merge) alinha-se com lead time for changes. O DORA 2025 report inclui pela primeira vez análise do impacto de AI coding assistants nas quatro métricas.

**SPACE Framework — Forsgren, Storey, Maddila, Zimmermann, Houck, Butler (2021)** — *"The SPACE of Developer Productivity"*
[ACM Queue, Vol. 19, No. 1](https://queue.acm.org/detail.cfm?id=3454124)
Define cinco dimensões de produtividade: **S**atisfaction, **P**erformance, **A**ctivity, **C**ommunication, **E**fficiency. As métricas deste runbook cobrem primariamente Activity (LoC, commits, PRs) e Efficiency (acceptance rate, time-to-merge). O paper argumenta que **nenhuma dimensão isolada** mede produtividade adequadamente — recomenda combinar pelo menos 3 dimensões.

**DX Core 4 — Michaela Greiler, Margaret-Anne Storey, Abi Noda (2024)** — *"DX Core 4: A Framework for Measuring Developer Experience"*
[IEEE Software, 2024]
Evolução do SPACE focada em developer experience. Define quatro dimensões core: speed, effectiveness, quality e impact. Argumenta que métricas de output (LoC, PRs) devem ser combinadas com métricas de percepção (surveys de satisfação do desenvolvedor) para dar uma visão completa. **Implicação:** ao apresentar resultados deste runbook, complementar com dados qualitativos (survey de adoção, NPS do Copilot).

### 14.6 Como Usar Estes Benchmarks

Ao apresentar os dados coletados por este runbook ao cliente, use os benchmarks desta seção para:

**Calibrar expectativas:** o RCT de Peng et al. mostra +55,8% de velocidade em tarefas isoladas, mas o estudo METR com trabalho real mostra ganhos mais modestos. Não prometa os números do melhor caso.

**Contextualizar volume com qualidade:** Ahmad et al. mostram +41% de complexidade com assistência de IA. Sempre apresente métricas de volume (LoC, PRs) junto com algum indicador de qualidade (cobertura de testes, code smells, bugs pós-merge).

**Interpretar PRs de agentes:** Li et al. mostram 83,8% de merge rate, mas Ji et al. mostram que PRs merged podem introduzir problemas pós-merge. A métrica `prs_merged_copilot_created` é necessária mas não suficiente.

**Esperar distribuição bimodal:** Guo et al. mostram que PRs de agentes são ou merged rapidamente ou abandonadas. Use histogramas além de medianas.

**Justificar a abordagem multi-camada:** o framework SPACE argumenta que nenhuma métrica isolada mede produtividade. As três camadas deste runbook (métricas diretas + correlação + análise de PRs) alinham-se com esta recomendação acadêmica.

-----

## References

- [REST API endpoints for Copilot usage metrics](https://docs.github.com/en/rest/copilot/copilot-usage-metrics)
- [GitHub Copilot usage metrics — Concepts](https://docs.github.com/en/copilot/concepts/copilot-usage-metrics/copilot-metrics)
- [Metrics data properties for GitHub Copilot](https://docs.github.com/en/copilot/reference/metrics-data)
- [Data available in Copilot usage metrics](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/copilot-usage-metrics)
- [Example schema for Copilot usage metrics](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/example-schema)
- [Lines of Code metrics](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/lines-of-code-metrics)
- [Interpreting usage and adoption metrics](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/interpret-copilot-metrics)
- [Reconciling Copilot usage metrics across dashboards, APIs, and reports](https://docs.github.com/en/copilot/reference/copilot-usage-metrics/reconciling-usage-metrics)
- [REST API endpoints for Copilot user management](https://docs.github.com/en/rest/copilot/copilot-user-management)
- [Viewing the Copilot usage metrics dashboard](https://docs.github.com/en/copilot/how-tos/administer-copilot/view-usage-and-adoption)
- [Closing down notice of legacy Copilot metrics APIs](https://github.blog/changelog/2026-01-29-closing-down-notice-of-legacy-copilot-metrics-apis/)
- [Copilot metrics is now generally available](https://github.blog/changelog/2026-02-27-copilot-metrics-is-now-generally-available/)
- [PR throughput and time-to-merge in Usage Metrics API](https://github.blog/changelog/2026-02-19-pull-request-throughput-and-time-to-merge-available-in-copilot-usage-metrics-api/)
- [Copilot-reviewed PR merge metrics in Usage Metrics API](https://github.blog/changelog/2026-04-08-copilot-reviewed-pull-request-merge-metrics-now-in-the-usage-metrics-api/)
- [Active and passive Copilot code review users](https://github.blog/changelog/2026-04-06-copilot-usage-metrics-now-identify-active-and-passive-copilot-code-review-users/)
- [Copilot cloud agent active user counts](https://github.blog/changelog/2026-04-10-copilot-usage-metrics-now-aggregate-copilot-cloud-agent-active-user-counts/)
- [Copilot CLI activity in usage metrics](https://github.blog/changelog/2026-04-10-copilot-cli-activity-now-included-in-usage-metrics-totals-and-feature-breakdowns/)
- [User-level CLI activity in org reports](https://github.blog/changelog/2026-03-05-copilot-usage-metrics-now-includes-user-level-github-copilot-cli-activity/)
- [About GitHub Copilot cloud agent](https://docs.github.com/copilot/concepts/agents/coding-agent/about-coding-agent)
- [Analyzing usage over time with the Copilot metrics API](https://docs.github.com/en/copilot/tutorials/roll-out-at-scale/measure-adoption/analyze-usage-over-time)
- [GitHub REST API: Commits](https://docs.github.com/en/rest/commits/commits)
- [GitHub REST API: Pull Requests](https://docs.github.com/en/rest/pulls/pulls)
- [GitHub REST API: Search Issues and Pull Requests](https://docs.github.com/en/rest/search/search#search-issues-and-pull-requests)
- [GitHub REST API: Repository Statistics](https://docs.github.com/en/rest/metrics/statistics)
- Peng, S., Kalliamvakou, E., Cihon, P., Demirer, M. (2023). "The Impact of AI on Developer Productivity: Evidence from GitHub Copilot." [arxiv:2302.06590](https://arxiv.org/abs/2302.06590)
- Cui, K., Chatterjee, S. et al. (2024). "The Effects of Generative AI on High Skilled Work: Evidence from Three Field Experiments at Google." [arxiv:2410.12944](https://arxiv.org/abs/2410.12944)
- Wijk, H., Dragan, A., Manheim, D. et al. (2025). "Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity." [arxiv:2507.09089](https://arxiv.org/abs/2507.09089)
- Liu, Y., Shen, B., Chen, J. et al. (2025). "From Intuition to Evidence: Quantifying the Impact of GitHub Copilot on Developer Productivity." [arxiv:2509.19708](https://arxiv.org/abs/2509.19708)
- Vailshery, L., Hejderup, J., Beller, M. (2025). "Agentic Much? Adoption of Coding Agents on GitHub."
- Pang, C., Guo, D., Li, Y. et al. (2025). "How AI Coding Agents Modify Code: A Large-Scale Study of GitHub Pull Requests."
- Suri, R., Smith, J., Zhang, L. et al. (2025). "A Large-Scale Empirical Study of AI-Generated Code in Real-World Repositories."
- Li, Y., Zhang, W., Yang, H. et al. (2025). "On the Use of Agentic Coding." [arxiv:2509.14745](https://arxiv.org/abs/2509.14745) — benchmark comparativo de coding agents
- Ahmad, W., Al-Kaswan, A., Vartziotis, E. et al. (2025). "Speed at the Cost of Quality? Quantifying the Impact of AI Assistance on Code." [arxiv:2511.04427](https://arxiv.org/abs/2511.04427)
- Zhong, H., Sun, Y., Wang, X. et al. (2025). "Quality Assurance of LLM-generated Code: A Systematic Literature Review and Industry Workshops." [arxiv:2511.10271](https://arxiv.org/abs/2511.10271)
- Jesse, K., Naseer, A., Tian, Y. et al. (2026). "Self-Admitted Technical Debt in LLM-Assisted Software Development." [arxiv:2601.06266](https://arxiv.org/abs/2601.06266)
- Song, Y., Wang, J., Wang, Z. et al. (2025). "Where Do AI Coding Agents Fail? A Large-Scale Study on GitHub Issues and Pull Requests."
- Ji, Z., Ji, S., Wang, X., Chen, Y. et al. (2026). "Beyond Bug Fixes: Post-Merge Code Quality Issues in Agent-Generated Pull Requests." [arxiv:2601.20109](https://arxiv.org/abs/2601.20109)
- Liu, Z., Liu, C., Chen, X. et al. (2026). "Why Are AI Agent-Involved Pull Requests Remain Unmerged?" [arxiv:2602.00164](https://arxiv.org/abs/2602.00164)
- Guo, Y., Chen, Z., Zhang, M. et al. (2026). "Early-Stage Prediction of Review Effort in AI-Generated Pull Requests." [arxiv:2601.00753](https://arxiv.org/abs/2601.00753)
- Forsgren, N., Storey, M.-A., Maddila, C., Zimmermann, T., Houck, B., Butler, J. (2021). "The SPACE of Developer Productivity." [ACM Queue, Vol. 19, No. 1](https://queue.acm.org/detail.cfm?id=3454124)
- Greiler, M., Storey, M.-A., Noda, A. (2024). "DX Core 4: A Framework for Measuring Developer Experience." IEEE Software, 2024.
