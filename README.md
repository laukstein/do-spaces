# DigitalOcean Spaces

GitHub Action to sync to DigitalOcean Spaces.

**⚠️ Note:** This action by default deletes all files in the space that are not present in `LOCAL_DIR`, disable using `DELETE_UNTRACKED: false`.


### Usage

Setup this workflow action like `.github/workflows/<name_this>.yml`

* Sync all repository
```yaml
name: DigitalOcean Spaces
on: push
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@main
      - name: Sync DigitalOcean Space
        uses: laukstein/do-spaces@main
        env:
          DO_ACCESS: ${{ secrets.DO_ACCESS }}
          DO_SECRET: ${{ secrets.DO_SECRET }}
          DO_NAME: ${{ secrets.DO_NAME }}
          DO_REGION: ams3
```

* Sync directory /public and purge changes from DigitalOcean CDN
```yaml
name: DigitalOcean Spaces
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
      - name: Get changes
        uses: tj-actions/changed-files@main
        id: changes
      - name: Sync DigitalOcean Space and purge from CDN
        uses: laukstein/do-spaces@main
        env:
          DO_TOKEN: ${{ secrets.DO_TOKEN }}
          DO_ACCESS: ${{ secrets.DO_ACCESS }}
          DO_SECRET: ${{ secrets.DO_SECRET }}
          DO_NAME: ${{ secrets.DO_NAME }}
          DO_REGION: ams3
          LOCAL_DIR: public
          CHANGES: ${{ steps.changes.outputs.all_changed_and_modified_files }}
```


### Required Variables

| Key | Value | Suggested Type | Required | Default |
| ------------- | ------------- | ------------- | --------- | --------- |
| `DO_ACCESS` | Your Spaces Access Key. [More info here.](https://www.digitalocean.com/community/tutorials/how-to-create-a-digitalocean-space-and-api-key) | `secret env` | **Yes** | N/A |
| `DO_SECRET` | Your Spaces Secret Access Key. [More info here.](https://www.digitalocean.com/community/tutorials/how-to-create-a-digitalocean-space-and-api-key) | `secret env` | **Yes** | N/A |
| `DO_NAME` | The name of the space you're syncing to. For example, `my-space`. | `secret env` | **Yes** | N/A |
| `DO_REGION` | The region where you created your space in. For example, `ams3`. [Full list of regions here.](https://www.digitalocean.com/docs/platform/availability-matrix/) | `env` | **Yes** | N/A |
| `SPACE_DIR` | The directory inside of the space you wish to sync to. For example, `my_project`. Defaults to the root of the space. | `env` | No | `/` |
| `LOCAL_DIR` | The local directory you wish to sync. For example, `public`. Defaults to your entire repository. | `env` | No | `/` |
| `DELETE_UNTRACKED` | If empty or set to `true`, deletes any files in the space that are *not* present in the source directory. | `env` | No | `true` |
| `FILES_PRIVATE` | Make files private, default `false`. | `env` | No | `false` |
| `ADD_HEADER` | Add custom header e.g. `Content-Encoding:gzip`. [See headers limited support.](https://docs.digitalocean.com/products/spaces/how-to/set-file-metadata/) | `env` | No | N/A |
| `DO_TOKEN` | Personal access token with Write scope, required to purge CDN. [See details.](https://docs.digitalocean.com/reference/api/create-personal-access-token/) | `secret env` | No | N/A |
| `CHANGES` | Changed files info, required to purge CDN. [See details.](https://github.com/tj-actions/changed-files) | `env` | No | N/A |


### License

This project is distributed under the [MIT license](LICENSE.md).
