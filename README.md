mdb2mysql
=========

**Version:** 1.1.0  
**Status:** Fully functional, but missing tests.

A tool to convert Microsoft Access databases into MySQL compatible SQL dump file. This file can then be imported into MySQL just like a standard SQL dump.

Requirements
------------
- Perl >= 5.8.4  
  See: https://www.perl.org

- mdbtools >= 0.7.1  
  See: https://github.com/brianb/mdbtools

Synopsis
--------

```
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
```

Changelog
---------

* v1.1.0

  - Added ability to specify character set for the incoming data in MySQL. This allows for the import of multilingual data from Access databases.

* v1.0.1

  - All table and column names are now quoted. Thus, fixing a problem when dealing with tables or column names that contain spaces as part of their name.

  - Illegal characters are now stripped out from table/column names by default rather then being replaced by an underscore. This is done to encourage the use of clean table/column names.

  - To avoid errors when trying to move NULL value from Access to MySQL, all columns within MySQL are now allowed to have NULL values. Also, since MDBTools do not export a default value for a column, it is now left to be set by MySQL.

* v1.0.0

  - First release by Bill Lewis <bill@enobis.com>

Donations
---------

This script is 100% free and is distributed under the terms of the MIT license. You're welcome to use it for private or commercial projects and to generally do whatever you want with it.

If you found this script useful, would like to support its further development, or you are just feeling generous, then your contribution will be greatly appreciated!

<p align="center">
  <a href="https://paypal.me/UmkaDK"><img src="https://img.shields.io/badge/paypal-me-blue.svg?colorB=0070ba&logo=paypal" alt="PayPal.Me"></a>
  &nbsp;
  <a href="https://commerce.coinbase.com/checkout/a57f47ba-6656-421c-aabd-3fdc274725ce"><img src="https://img.shields.io/badge/coinbase-donate-gold.svg?colorB=ff8e00&logo=bitcoin" alt="Donate via Coinbase"></a>
</p>
