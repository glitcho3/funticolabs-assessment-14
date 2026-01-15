FROM cgr.dev/chainguard/wolfi-base

RUN apk add npm bash curl nodejs

RUN adduser -D appuser
USER appuser
WORKDIR /home/appuser

ENV NVM_DIR=/home/appuser/.nvm
ENV NODE_VERSION=20.19.6
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

RUN bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION"

WORKDIR /app

COPY --chown=appuser:appuser package.json package-lock.json ./
COPY --chown=appuser:appuser . .

#CMD ["node", "--version"]
CMD ["npm", "run", "api-sc-test"]


