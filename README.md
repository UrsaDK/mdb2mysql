mdb2sql
=======

**Version:** 1.1.0  
**Status:** Fully functional, but missing tests.

A tool to convert Microsoft Access databases into MySQL compatible SQL dump file, which would allow you to import the data in to MySQL.

Requirements
------------
- Perl >= 5.8.4  
  See: https://www.perl.org

- mdbtools >= 0.7.1  
  See: https://github.com/brianb/mdbtools

Usage
-----

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
