# silex.sile

[![license](https://img.shields.io/github/license/Omikhleia/silex.sile?label=License)](LICENSE)
[![Luacheck](https://img.shields.io/github/actions/workflow/status/Omikhleia/silex.sile/luacheck.yml?branch=main&label=Luacheck&logo=Lua)](https://github.com/Omikhleia/silex.sile/actions?workflow=Luacheck)
[![Luarocks](https://img.shields.io/luarocks/v/Omikhleia/silex.sile?label=Luarocks&logo=Lua)](https://luarocks.org/modules/Omikhleia/silex.sile)

A silex is a kind of hard stone.

This is **sile·x**, a common layer for [**re·sil·ient**](https://github.com/Omikhleia/resilient.sile) and other modules:
Some common bricks and blocks, opinionated hacks, and eXperimental eXpansions, hence the name.

:warning: **sile·x** overrides several SILE internals when fully enabled, and may therefore break some of your packages and classes.

### Installation and removal

Install with [Luarocks](https://luarocks.org/):

```shell
luarocks install silex.sile
```

Uninstall:

```shell
luarocks remove silex.sile
```

Obviously, modules needing it (and therefore also intalling it as a dependency), such as [markdown.sile](https://github.com/Omikhleia/markdown.sile) and [resilient.sile](https://github.com/Omikhleia/resilient.sile) (amongst others) will not work without it.

## Features

**classes** and **typesetters** :warning: Opinionated departure from SILE 0.14.

Modified implementation of the base typesetter and class.

- Propagation of hanged indent from paragraph to paragraph.

  _Rationale:_
  See [SILE discussion 1742](https://github.com/sile-typesetter/sile/discussions/1742)

- Multi-liners i.e. support for environment spanning multiple lines.

  _Rationale:_
  Early adoption of SILE PR [1977](https://github.com/sile-typesetter/sile/pull/1977)

**silex.lang**

This module overrides the language support in SILE to accept and resolve BCP47 language tags, such as `en-GB`, `es-MX`, `fr-CH`, etc.
In other layman's terms, it changes the behavior of SILE's `\language` command.
This implementation does _not_ change how SILE's `\font[language=...]` command works.

_Rationale:_
See [SILE PR 1641](https://github.com/sile-typesetter/sile/pull/1641) for details and more complete proposal.
We cannot wait forever for SILE to implement this: Markdown and Djot need to be able to support qualified language names, notably for smart quotes to work adequately.

## Affected modules

If you use packages or classes from the following modules, some features of **silex** will be loaded globally. Your documents using them may therefore be impacted from that point.

- The packages from [smartquotes.sile](https://github.com/Omikhleia/smartquotes.sile) enable **silex.lang**.

- The packages and inputters from [markdown.sile](https://github.com/Omikhleia/markdown.sile) enable **silex.lang**.

- The packages and classes from [resilient.sile](https://github.com/Omikhleia/resilient.sile) enable **all** features.

As noted, some global changes are also introduced in the typesetter and base document class. Side-effects are therefore possible on some workflows.

## Future directions

The plan: SILE + **sile·x** + **re·sil·ient** = SILE as it should be.

Did I say this was opinionated?
Whatever you may think, expect some more breaking changes and furious experiments in the future...

## License

All code is under the MIT License.
