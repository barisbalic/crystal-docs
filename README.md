# crystal-docs

The code behind the [crystal-docs.org](https://crystal-docs.org) website.


## Development

You will need to specify the following environment variables:

- `GITHUB_TOKEN` used to check presence of Crystal in repositories.
- `RELEASE_PATH` destination for Crystal releases.
- `CRYSTALDOCS_PLATFORM` the target platform.
- `REPO_PATH` destination for repositories.
- `DOC_PATH` destination for built documentation.

You can build and run like so...

```sh
$ crystal build src/crystal-docs
$ REPO_PATH=/tmp/repos DOC_PATH=/var/www GITHUB_TOKEN=abc RELEASE_PATH=/tmp/crystal-releases CRYSTALDOCS_PLATFORM=darwin-x86_64 ./crystal-docs
```


## Contributing

1. Fork it ( https://github.com/barisbalic/crystal-docs/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [barisbalic](https://github.com/barisbalic) Baris Balic - creator, maintainer
