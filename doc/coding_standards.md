# Coding Standards/Guidelines

NUcore is an old project and has passed through many hands. There are long controller methods, complex view logic, and odd routing. It began as a Rails 2.X project and pieces of that legacy remain. Many of the things that you may consider as bad may have even been considered best practices at the time. Give the past developers some credit. Future you may have similar things to say about what you're doing right now.

Times have changed, styles and best practices have evolved, and we want to keep the codebase healthy. That means cleaning things up and refactoring as needed. We can't fix everything at once, but we can make things better one little piece at a time.

If you see a nasty or incomprehensible method, see if you can refactor it to make it more understandable. If you're trying to make a change and it's hard, [refactor to make the change easy](https://twitter.com/kentbeck/status/250733358307500032).

But do consider the value vs effort. If it's a bug fix where you have `>` instead of `>=`, it might not be worth spending four hours refactoring. But if you're working within a nasty method and you know there's constant churn on that class, it's likely worth it.

The golden rule: **when working on a piece of code, _leave it nicer than when you found it_**.

Here are some general guidelines:

## Pull Requests

**Do not commit to master!**

All changes should go through a Pull Request and be reviewed prior to merging.

## Bug fixes

If you're tracking down a bug, write a test for it. Even if you fix the bug first, undo your change, write a failing test, and then re-do your change to make it pass.

## Rubocop

We have rubocop set up with a set of style guidelines. When you're working in a file,
try to abide the guidelines (e.g. prefer double over single quotes, use 1.9-style
hash syntax, etc). Please run `rubocop` on the files you're touching, and preferably only
on the files you're touching.

It's difficult to see a salient change amidst a lot of stylistic updates, so if you
run rubocop or do another large stylistic update, give it a separate commit, or even
its own PR if the changes are significant enough.

## Fork-specific changes

Some features such as authentication or financial system integration may be specific to
a particular instance of NUcore. These kinds of features should be developed within their
respective downstream forks. When developing these kinds of features, it is important to
avoid making changes to application code (primarily `/app` and `/lib`) that also exists in
the open-source fork. Otherwise, there is a high likelyhood of merge conflict if anything
changes upstream.

The best method is to isolate your feature inside of an engine in `vendor/engines`. When
necessary, create a hook point where you need it within the open-source branch and hook
into that with your engine. Try to avoid overriding entire views (like happens in the `c2po` engine). Then a change to the default view might need to happen in multiple places.

_We have yet to find a perfect mechanism for this, but some options include:_

* A factory configured in settings (e.g. `ValidatorFactory`, `StatementPdfFactory`
* Adding a module onto an existing class in the engine initializer (see `vendor/engines/c2po/lib/c2po.rb`)
* Other things we haven't thought of

## Gemfiles

There will necessarily be differences between the `Gemfile`s of different instances (the
included engines, database, etc.). Do your best to keep the common gems in Gemfiles are in
the same order. This will help prevent merge conflicts in `Gemfile`. Unfortunately, merge
conflicts within `Gemfile.lock` are likely inevitable.

If you are building an engine that depends on an additional gem, add that dependency to the
engine's `gemspec`, not app's `Gemfile`.

_We should consider `optional` groups in Bundler 1.10 to see if this helps_

## Commits

Prefix your commits and pull requests with the ticket number. `[#12345] Fix critical issue`

[TODO]

## Other

### Refactor Scopes
There are plenty of old-style scopes and finders (`find(:all, conditions: ...)`, `scope :xxxx, conditions: ...`, etc) lying around from when NUcore was young. Always use the newer style, and fix up scopes as you have the opportunity.

### Prepare for Rails Upgrades
Since this is still a Rails 3.2 project, you may find yourself needing to use
outmoded idioms like a dynamic finders. Tag these with `TODO:` comments so we
can more easily find them with `rake notes`.

### Put application code where it belongs
There is quite a bit of code inside of `/lib` that is actually application code. Many of the
classes/modules are actually service objects or model concerns. Move them to the appropriate
place inside of `/app`.

We have an `app/support` directory that probably would be more at home in `app/services` or `app/models/concerns`. Move them to where they belong.

Don't worry too much about moving code you're not actively working with. But when you do work on
something that seems to be in the wrong place, please fix it!

### Don't use DCI
There are a few places where we are using (DCI)[http://www.sitepoint.com/dci-the-evolution-of-the-object-oriented-paradigm/] such as `PriceDisplayment`. Do not use this technique going forward. Prefer decorators/presenters. Prefer `SimpleDelegator` for your decorators; we have
chosen not to use something more magical like Draper.

### Documentation
If a class is not immediately obvious what its purpose is, add comments to the top of the
class explaining its purpose and its use.

### Skinny Models, Controllers, and Views
You'll see lots of long controller methods or complex logic in the views. Don't contribute to the problem. If you need to touch one of these, start by refactoring out a service object or presenter. Additionally, try to avoid adding additional business logic onto the models. `OrderDetail` is already large enough!

### Roles
Prefer `Ability` checks (`can? :read, @order_detail)` over Role checks in views and controllers (e.g. `User#manager_of?(facility)`).

## Once again, leave things better than you found them.

And remember, break any of these rules sooner than do anything outright barbarous.
