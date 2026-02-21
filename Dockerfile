################################################################################
# Args
################################################################################

ARG BUILDER_IMAGE_NAME=rbuchss/git-friends-tester-builder
ARG IMAGE_BASH_PATH=/usr/local/bin/bash
ARG USER=kyle-reese
ARG GROUP=skynet-resistance
ARG WORKDIR=/cyberdyne

################################################################################
# Tester Image - Uses builder image to speed up test image setup
################################################################################

FROM ${BUILDER_IMAGE_NAME} AS git-friends-tester-base

# We need to export any ARG's we want in each stage to make them available
ARG IMAGE_BASH_PATH
ARG USER
ARG GROUP

ENV BASH_PATH=${IMAGE_BASH_PATH}

RUN addgroup ${GROUP}
RUN adduser \
  --disabled-password \
  --gecos "" \
  --shell ${BASH_PATH} \
  --ingroup ${GROUP} \
  ${USER}

################################################################################
# Local docker version
################################################################################

FROM git-friends-tester-base AS git-friends-tester-local

# We need to export any ARG's we want in each stage to make them available
ARG USER
ARG GROUP
ARG WORKDIR

WORKDIR ${WORKDIR}

ENV GIT_FRIENDS_MODULE_SRC_DIR=${WORKDIR}/git-friends/src

RUN chown --recursive ${USER}:${GROUP} ${WORKDIR}

USER ${USER}

COPY --chown=${USER}:${GROUP} . .

CMD exec make guards

################################################################################
# Github actions docker version
# Note Github recommends that we do not set USER and WORKDIR:
# ref https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions
################################################################################

FROM git-friends-tester-base AS git-friends-tester-github-actions

ARG USER
ARG GROUP

# Set working directory for GitHub Actions (even though GH docs recommend not to,
# we need it to properly locate git-friends source files)
WORKDIR /github/workspace

ENV GIT_FRIENDS_MODULE_SRC_DIR=/github/workspace/git-friends/src

COPY --chown=${USER}:${GROUP} . .

ENTRYPOINT ["./.github/actions/run-make/entrypoint.sh"]
