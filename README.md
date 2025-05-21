# bugs.ruby-lang.org

The fork of [redmine/redmine](https://github.com/redmine/redmine) for https://bugs.ruby-lang.org.

# Trouble shooting

## Git repository sync is not working

We have a known issue with the git repository sync. If you encounter a problem with the sync, please check the following:

1. Run the following command to sync the git repository manually:
   ```bash
   heroku run:detached bundle exec rails runner Repository.fetch_changesets -a bugs-ruby-lang -s performance-l
   ```
   and track the logs with:
   ```bash
   heroku logs --app bugs-ruby-lang --dyno run.4071 -t
   ```
   `run.4071` is the dyno name, which may be different in your case. You can find that name in the previous command output.
   ```

    If you can't see the logs, you can run the following command on the one-off dyno:
    ```bash
    heroku run bash -a bugs-ruby-lang -s performance-l
    ```
    and
    ```bash
    bin/rails runner Repository.fetch_changesets
    ```

2. If you see like the following error:
   ```
   fatal: bad object 808d6a1e324703152f7fde67aea3d2ba52b6aba1
   ```
   It means the following reason:
   * The bare repository on heroku is corrupted.
   * The changesets of redmine is corrupted.
   * The canonical repository is corrupted.

### To fix corrupted bare repository

Deploy the new revision to heroku:

```bash
git commit --allow-empty -m "fix: corrupted bare repository"
git push heroku main
```

and run the following command to sync the git repository manually:

```bash
heroku run:detached bundle exec rails runner Repository.fetch_changesets -a bugs-ruby-lang -s performance-l
```

### To fix corrupted changesets

This error may happen when the tag is removed from the canonical repository. Redmine is not able to handle that case. We need to remove and retrieve the changesets again.

1. Delete the current changesets: Go to the https://bugs.ruby-lang.org/projects/ruby-master/settings/repositories and delete the `git` changeset.
2. Clieck `New repository` and fill `git` to "Identifier" and `/app/repos/git/ruby` to "Path to repository". After that, clieck `Save` button.
3. Run the following command to sync the git repository manually:
   ```bash
   heroku run:detached bundle exec rails runner Repository.fetch_changesets -a bugs-ruby-lang -s performance-l
   ```

### The canonical repository is corrupted

In this case, please contact @hsbt, @k0kubun or @mame. We need to fix the canonical repository used by `git fsck` or `git gc` command.

After that, we need to process to fix corrupted bare repository and corrupted changesets.
