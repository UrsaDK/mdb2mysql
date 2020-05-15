<div align="center">

  [![mdb2mysql logo](https://avatars.githubusercontent.com/u/2833247?s=160)](#)<br>

  [![stable branch](https://img.shields.io/badge/dynamic/json.svg?logo=github&color=lightgrey&label=stable&query=%24.default_branch&url=https%3A%2F%2Fapi.github.com%2Frepos%2FUrsaDK%2Fmdb2mysql)](https://github.com/UrsaDK/mdb2mysql)
  [![latest release](https://img.shields.io/badge/dynamic/json.svg?logo=github&color=blue&label=release&query=%24.name&url=https%3A%2F%2Fapi.github.com%2Frepos%2FUrsaDK%2Fmdb2mysql%2Freleases%2Flatest)](https://github.com/UrsaDK/mdb2mysql/releases/latest)
  [![donate link](https://img.shields.io/badge/donate-coinbase-gold.svg?colorB=ff8e00&logo=bitcoin)](https://commerce.coinbase.com/checkout/a57f47ba-6656-421c-aabd-3fdc274725ce)

</div>

# mdb2mysql

A tool to convert Microsoft Access databases into MySQL compatible SQL dump file. This file can then be imported into MySQL just like a standard SQL dump.

- [Requirements](#requirements)
- [Synopsis](#synopsis)
- [Changelog](#changelog)

## Requirements

  - [Perl](https://www.perl.org) >= 5.8.4
  - [mdbtools](https://github.com/brianb/mdbtools) >= 0.7.1

## Synopsis

    mdb2mysql [options] <mdb file>
      -c             Create table structure only, no data.
      -d             Add a 'drop table' before each create.
      -e             Use the much faster, extended INSERT syntax.
      -i             Export data inserts only.
      -l             Add locks around insert statements.
      -o <tables>    Omit tables in this comma seperated list.
      -r <character> Replace illegal characters with given character.
      -t <tables>    Export only this list of comma seperated tables.
      -u             Report unknown Access data type and exit.
      -x             Same as using -d -e -l combined options.
      -M             Convert Access System tables ('MSys') as well.
      -C <type>      Define character set of the transferred data.
      -U <type>      Use the MySQL data type for unknown Access types.
                    Unless given, 'blob' will be used by default.
      -h, --help     This message and exit.
      -V, --version  Output version information and exit.

## Changelog

* v1.1.1

  - Minor documentation updates.
  - Reverted to GNU General Public License v3.

* v1.1.0

  - Added ability to specify character set for the incoming data in MySQL. This allows for the import of multilingual data from Access databases.

* v1.0.1

  - All table and column names are now quoted. Thus, fixing a problem when dealing with tables or column names that contain spaces as part of their name.

  - Illegal characters are now stripped out from table/column names by default rather then being replaced by an underscore. This is done to encourage the use of clean table/column names.

  - To avoid errors when trying to move NULL value from Access to MySQL, all columns within MySQL are now allowed to have NULL values. Also, since MDBTools do not export a default value for a column, it is now left to be set by MySQL.

* v1.0.0

  - First release by Bill Lewis <bill@enobis.com>
