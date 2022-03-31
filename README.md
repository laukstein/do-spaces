# DigitalOcean Spaces Action

GitHub Action to sync DigitalOcean Spaces, purge changes from DigitalOcean CDN and Cloudflare cache.

⚠️ Set `DELETE_UNTRACKED: false` if you wish to keep files in space that are not present in `LOCAL_DIR`.


### Usage

Setup this workflow action like `.github/workflows/<name_this>.yml`

* Sync all repository
```yaml
name: DigitalOcean Spaces Action
on: push
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@main
      - name: Sync DigitalOcean Spac
        uses: laukstein/do-spaces@main
        env:
          DO_ACCESS: ${{ secrets.DO_ACCESS }}
          DO_SECRET: ${{ secrets.DO_SECRET }}
          DO_NAME: ${{ secrets.DO_NAME }}
          DO_REGION: ams3
```

* Sync directory /public and purge changes from DigitalOcean CDN
```yaml
name: DigitalOcean Spaces Action
on:
  push:
    paths: public/**
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@main
        with:
          fetch-depth: 0
      - name: Sync DigitalOcean Spac, purge changes from the CDN
        uses: laukstein/do-spaces@main
        env:
          DO_TOKEN: ${{ secrets.DO_TOKEN }}
          DO_ACCESS: ${{ secrets.DO_ACCESS }}
          DO_SECRET: ${{ secrets.DO_SECRET }}
          DO_NAME: ${{ secrets.DO_NAME }}
          DO_REGION: ams3
          LOCAL_DIR: public
```

* Sync directory /public to https://cdn.mydomain.com/img/ and purge changes from DigitalOcean CDN and Cloudflare cache
```yaml
name: DigitalOcean Spaces Action
on:
  push:
    paths: public/**
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@main
        with:
          fetch-depth: 0
      - name: Sync DigitalOcean Space, purge changes from the CDN and Cloudflare cache
        uses: laukstein/do-spaces@main
        env:
          DO_TOKEN: ${{ secrets.DO_TOKEN }}
          DO_ACCESS: ${{ secrets.DO_ACCESS }}
          DO_SECRET: ${{ secrets.DO_SECRET }}
          DO_NAME: ${{ secrets.DO_NAME }}
          DO_REGION: ams3
          DO_DIR: img
          CF_TOKEN: ${{ secrets.CF_TOKEN }}
          CF_ZONE: ${{ secrets.CF_ZONE }}
          CF_URL: https://cdn.mydomain.com/img/
          LOCAL_DIR: public
```


### DigitalOcean Space variables

| Key | Value | Suggested Type | Required | Default |
| ------------- | ------------- | ------------- | --------- | --------- |
| `DO_ACCESS` | Your Spaces Access Key. [See details.](https://www.digitalocean.com/community/tutorials/how-to-create-a-digitalocean-space-and-api-key) | `secret env` | **Yes** | N/A |
| `DO_SECRET` | Your Spaces Secret Access Key. [See details.](https://www.digitalocean.com/community/tutorials/how-to-create-a-digitalocean-space-and-api-key) | `secret env` | **Yes** | N/A |
| `DO_NAME` | The name of the space you're syncing to. For example, `my-space`. | `secret env` | **Yes** | N/A |
| `DO_REGION` | The region where you created your space in. For example, `ams3`. [See supported regions.](https://www.digitalocean.com/docs/platform/availability-matrix/) | `env` | **Yes** | N/A |
| `DO_DIR` | The directory inside of the space you wish to sync to. For example, `my_project`. Defaults to the root of the space. | `env` | No | `/` |
| `LOCAL_DIR` | The local directory you wish to sync. For example, `public`. Defaults to your entire repository. | `env` | No | `/` |
| `DELETE_UNTRACKED` | If empty or set to `true`, deletes any files in the space that are *not* present in the source directory. | `env` | No | `true` |
| `FILES_PRIVATE` | Make files private, default `false`. | `env` | No | `false` |
| `ADD_HEADER` | Add custom header e.g. `Content-Encoding:gzip`. [See supported headers.](https://docs.digitalocean.com/products/spaces/how-to/set-file-metadata/) | `env` | No | N/A |
| `DO_TOKEN` | Personal access token with Write scope, required only to purge DigitalOcean CDN. [See details.](https://docs.digitalocean.com/reference/api/create-personal-access-token/)  | `secret env` | No | N/A |

#### Cloudflare purge cache variables

| Key | Value | Suggested Type | Required | Default |
| ------------- | ------------- | ------------- | --------- | --------- |
| `CF_TOKEN` | Cloudflare token with zone access to Purge cache. [See details.](https://developers.cloudflare.com/api/tokens/create/)  | `secret env` | No | N/A |
| `CF_ZONE` | Cloudflare Zone ID, can find in Cloudflare Overview tab for the domain. | `secret env` | No | N/A |
| `CF_URL` | e.g. https://cdn.mydomain.com/img/ or https://cdn.mydomain.com where the CDN is used on enabled Cloudflare proxy. | `env` | No | N/A |


### License

This project is distributed under the [MIT license](LICENSE.md).
