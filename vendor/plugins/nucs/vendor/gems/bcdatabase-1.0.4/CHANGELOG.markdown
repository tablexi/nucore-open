1.0.4
=====
- Fix command line utilities that were broken in 1.0.3 due to
  inadequate test coverage.  (GH-4)

1.0.3
=====
- Support ActiveSupport 3.  ActiveSupport 2 continues to work.

1.0.2
=====
- Tighten up gemspec gem deps.  Bcdatabase does not currently work
  with ActiveSupport 3.

1.0.1
=====
- Update some old syntax for ruby 1.9 compatibility (David Yip)

1.0.0
=====
- Split out from NUBIC internal `bcdatabase` project.
  (Changelog entries below reflect the relevant changes & version numbers from that project.)

0.4.1
=====
- Fix `bcdatabase encrypt` so that it doesn't re-encrypt already encrypted
  epassword entries.

0.4.0
=====
- Use the YAML entry name as the "database" value if no other value is
  provided.  This is to DRY up PostgreSQL configurations where the username
  (already defaulted) and the database name are the same.

0.2.0
=====
- Change default encrypted secret password location

0.1.0
=====
- Support encrypted passwords
- Command-line utility (also called bcdatabase) for creating encrypted passwords
- Gem distribution

0.0.0
=====
Original release.
