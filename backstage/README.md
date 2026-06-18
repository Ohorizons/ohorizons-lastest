# Open Horizons distribution of Backstage

This directory is the **Open Horizons distribution of [Backstage](https://backstage.io) OSS**.
It is the upstream Backstage application, pinned to a specific OSS release, built
with the Open Horizons custom plugins and pages, and published as a single,
immutable container image.

> The runtime image is **not** a hand-made or screenshot-based image. It is the
> official Backstage OSS app, compiled with our customizations, and tagged with a
> pinned version. `latest` is never deployed.

## Upstream version

| Item | Value |
| --- | --- |
| Backstage OSS release | `1.48.3` (see [`backstage.json`](backstage.json)) |
| Distribution image | `ghcr.io/ohorizons/ohorizons-backstage` |
| Current pinned tag | `v7.2.4` |
| Image build | [Dockerfile.acr](Dockerfile.acr) and [release-images workflow](../.github/workflows/release-images.yml) |

To move to a newer Backstage release, bump the `@backstage/*` dependencies and
`backstage.json`, rebuild the distribution image, run the test suite, and publish
a new pinned tag. Do not point deployments at a moving tag.

## What the distribution adds

On top of upstream Backstage core (catalog, scaffolder, TechDocs), the
distribution bundles the Open Horizons custom experience:

- Custom sign-in and landing pages under [packages/app/src/components](packages/app/src/components).
- Platform and observability pages.
- The **AI Chat** and **AI Impact** plugins under [plugins/](plugins/).
- Golden Path templates and catalog wiring.

These are compiled into the image but enabled per environment through the
installer. A clean **base** install ships only the Backstage core experience;
the **platform**, **full**, and **custom** profiles enable additional pages and
plugins.

## Install and enablement model

1. **Base install** — the [install wizard](../scripts/install-wizard.sh) deploys
   the distribution image with the Backstage core experience and the customer's
   identity and catalog configuration.
2. **Post-install enablement** — the wizard then asks whether to enable the
   Open Horizons custom plugins and pages and the standard Backstage public
   plugins, and collects only the integration data each choice needs (GitHub App,
   organization, Azure DevOps, Microsoft Entra ID, domain, and Azure OpenAI or
   Foundry for AI features).

See the [Master Installation guide](../docs/guides/MASTER_INSTALLATION.md) for the
full flow.

## Local development

```sh
yarn install
yarn start
```

For production configuration, see [app-config.production.yaml](app-config.production.yaml).
