# How to Contribute

Please refer to the [readme](https://github.com/tablexi/nucore-open/blob/master/README.md) for spin-up information and basic context. 

## Opening a Pull Request

Once you're ready to open a pull request, please follow our pull request template for your PR description. Please include tests for any new functionality added. Refer to our [Coding Standards](https://github.com/tablexi/nucore-open/blob/master/doc/coding_standards.md) for information on style guidelines and best practices. Once your PR is approved, please squash commits and paste the "Release Notes" section from the PR description as the commit message for the PR.

## Does this change belong in open?

Some features such as authentication or financial system integration may be specific to a particular instance of NUcore. These kinds of features should be developed within their respective downstream forks. When developing these kinds of features, it is important to avoid making changes to application code (primarily /app and /lib) that also exists in the open-source fork. Otherwise, there is a high likelyhood of merge conflict if anything changes upstream.

For additional information, see [Coding Standards - Fork Specific Changes](https://github.com/tablexi/nucore-open/blob/master/doc/coding_standards.md#fork-specific-changes).
