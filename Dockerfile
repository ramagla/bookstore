# Define a base de imagem com Python 3.12.5
FROM python:3.12.5-slim AS python-base

# Configura variáveis de ambiente
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=1.8.3 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

# Adiciona o Poetry e o virtual environment ao PATH
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# Instala dependências do sistema
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instala dockerize
RUN curl -sL https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz | tar -C /usr/local/bin -xzv

# Instala o Poetry
RUN pip install poetry

# Instala dependências do PostgreSQL
RUN apt-get update \
    && apt-get -y install libpq-dev gcc \
    && pip install psycopg2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho para a instalação das dependências
WORKDIR $PYSETUP_PATH

# Copia os arquivos de dependências do Poetry
COPY poetry.lock pyproject.toml ./

# Instala as dependências do projeto sem as de desenvolvimento
RUN poetry install --no-dev

# Instala as dependências restantes
RUN poetry install

# Define o diretório de trabalho para o código da aplicação
WORKDIR /app

# Copia todo o código da aplicação para o contêiner
COPY . /app/

# Expõe a porta 8000
EXPOSE 8000

# Comando para iniciar a aplicação
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
