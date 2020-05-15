#!/usr/bin/perl
##########
#
#  File: mdb2mysql
#  Repo: https://github.com/UrsaDK/mdb2mysql
#
#  Created By:   Bill Lewis <bill@enobis.com>
#  Updated By:   Dmytro Konstantinov <ursa.dk@icloud.com>
#
#  Description:  Perl script to convert MS Access (mdb) files to an import
#                schema suitable for MySQL.
#
#  Requirements: Perl (obvioulsy)
#                mdbtools (mdbtools.sourceforge.net)
#
#  This is free software; you can redistribute it and/or modify it under
#  the terms of the GNU General Public License as published by the Free
#  Software Foundation.  You should have received a copy of the GNU
#  General Public License along with this software; if not, visit:
#
#            http://www.gnu.org/copyleft/gpl.html
#
#############################################################################
use strict;
use Getopt::Std;

my $VERSION = "MDB2MySQL v1.1.1";

##########
#
#  Initialize Execution Environment
#
#############################################################################
our %opts;

# Set defaults...
$opts{"r"} = "";
$opts{"U"} = "blob";
$Getopt::Std::STANDARD_HELP_VERSION=1;

getopts('cdeilhsuxMVo:r:t:U:C:',\%opts);

if($opts{"h"}) { &VERSION_MESSAGE; &HELP_MESSAGE; exit; }
if($opts{"V"}) { &VERSION_MESSAGE; exit; }

if(@ARGV < 1) { &VERSION_MESSAGE; &HELP_MESSAGE; exit; }
my $dataFile = $ARGV[$#ARGV];

if($opts{"x"})
{
  $opts{"d"} = 1;
  $opts{"e"} = 1;
  $opts{"l"} = 1;
}

my $delim = "__zz__";

my %mdbversions = ( "JET3" => "Access 97", "JET4" => "Access 2000/XP" );

##########
#
#  MDB2MySQL Header Information
#
#############################################################################

# Get MDB File Version
open(VER,"mdb-ver $dataFile|") || die "Error Reading MDB File: $!\n";
my $dataFileVersion = <VER>;
close(VER);
chop $dataFileVersion;
$dataFileVersion .= " (".$mdbversions{$dataFileVersion}.")";

# Print Header Information
print <<EOHEAD;
-- $VERSION
--
-- Created By: Bill Lewis <bill\@enobis.com>
-- Updated By: Dmytro Konstantinov <ursa.dk\@icloud.com>
--
-- Copyright 2004
--
-- GNU General Public License
----------------------------------------------------------------------
-- MDB File: $dataFile
-- MDB Version: $dataFileVersion

EOHEAD

##########
#
#  Script body
#
#############################################################################

# Get List of Tables
my @tables;
my $mdbtables = "mdb-tables -d".$delim;
if($opts{"M"}) { $mdbtables .= " -S"; }

if($opts{"t"})
{
  @tables = split(/,/,$opts{"t"});
}
else
{
  open(TABLES,"$mdbtables $dataFile|") || die "Error Reading Tables: $!\n";
  if(!$opts{"M"})
  {
    $_ = <TABLES>;
    chop;
    @tables = split(/$delim/);
  }
  else
  {
    while(<TABLES>)
    {
      chop;
      push(@tables,$_);
    }
  }
  close(TABLES);
  if($opts{"o"})
  {
    my %hash = ();
    foreach (@tables,split(/,/,$opts{"o"})) { $hash{$_}++; }
    @tables = ();
    foreach (keys %hash) { if($hash{$_} == 1) { push(@tables,$_); } }
  }
}

# Loop through the tables to build the MySQL import/SQL format
my @headers;
my ($tbl,$record,$firstrecord,$first,$multirow,$startmulti,$endmulti,$values);
my $mdbexport = "mdb-export -d ".$delim." \"%s\" \"%s\" |";
foreach $tbl (@tables)
{
  if(!$opts{"i"}) { &createTableSchema($dataFile,$tbl); }

  if($opts{"c"}) { next; }

  print "--\n--  Dumping data for table \"$tbl\"\n--\n\n";

  # Get Table Data Records
  open(RECORDS,sprintf($mdbexport,$dataFile,$tbl)) ||
       die "Error Exporting Record Data: $!\n";

  # Get Headers in case of future development/features...
  foreach (split(/$delim/,<RECORDS>))
  {
    s/[^a-zA-Z0-9_\$]/$opts{"r"}/g;
    push(@headers,$_);
  }

  $firstrecord = 1;
  $multirow = $startmulti = $endmulti = 0;
  if($opts{"l"}) { print "LOCK TABLES `$tbl` WRITE;\n"; }
  if($opts{"e"}) { print "INSERT INTO `$tbl` VALUES "; }
  while(<RECORDS>)
  {
    if(!$multirow)
    {
      chop;
      $first = 1;
      $values = "";
    }
    foreach (split(/$delim/))
    {
      if(!$multirow)
      {
        # Strip Quotes from both sides of data value
        if(substr($_,0,1) eq '"' && substr($_,-1,1) eq '"')
        {
          $_ = substr($_,1,$#_);
        }
        # Strip out quotes from both sides on an unchoped row resulting
        # from a multirow data record.
        elsif(substr($_,0,1) eq '"' && substr($_,-2,1) eq '"')
        {
          $_ = substr($_,1,$#_-1);
        }
        # Check to see if this data value is the start of a multirow
        elsif(substr($_,0,1) eq '"')
        {
          $_ = substr($_,1);
          $multirow = 1;
          $startmulti = 1;
        }
      }
      else
      {
        # Check to see if this data is the end of a multirow
        # Start by verifying that a quotation mark at the end of the
        # line is not part of the data...
        if(substr($_,-2) ne '""' || substr($_,-3,2) ne '""')
        {
          if(substr($_,-1,1) eq '"')
          {
            $_ = substr($_,0,$#_);
            $multirow = 0;
            $endmulti = 1;
          }
          elsif(substr($_,-2,1) eq '"')
          {
            $_ = substr($_,0,$#_-1);
            $multirow = 0;
            $endmulti = 1;
          }
        }
      }

      # Need to check if the field is a date type
      # and convert to acceptable MySQL format if so...
      if(!$multirow && !$endmulti)
      {
        if(/^(\d{1,2})\/(\d{1,2})\/(\d{2,4})\s+(\d{1,2}):(\d{1,2}):(\d{1,2})/ ||
          /^(\d{1,2})\/(\d{1,2})\/(\d{2,4})/)
        {
          $_ = sprintf("%s%02s%02s%02s%02s%02s",$3,$1,$2,$4,$5,$6);
        }
      }

      # Escape and convert certain characters for MySQL format
      s/\\/\\\\/g;
      s/'/\\'/g;
      s/""/"/g;
      s/"/\\"/g;

      # Create MySQL format for dump values
      if(!$multirow)
      {
        if(!$first && !$endmulti) { $values .= ","; }

        if(!$endmulti) { $values .= "'".$_."'"; }
        else { $values .= $_."'"; $endmulti = 0; }
      }
      else
      {
        if($startmulti)
        {
          if(!$first) { $values .= ","; }
          $values .= "'".$_;
          $startmulti = 0;
        }
        else
        {
          $values .= $_;
        }
      }

      $first = 0;
    }
    if(!$multirow)
    {
      if($opts{"e"})
      {
        if(!$firstrecord) { print ","; }
        print "($values)";
        $firstrecord = 0;
      }
      else
      {
        printf("INSERT INTO `%s` VALUES (%s);\n",$tbl,$values);
      }
    }
  }
  if($opts{"e"}) { print ";\n"; }
  if($opts{"l"}) { print "UNLOCK TABLES;\n\n"; }

  close(RECORDS);
}

exit;

##########
#
#  Subroutine: createTableSchema
#
#  Description: Creates the table structure in MySQL format.
#
#  Arguments: $mdbFile - MDB Database file containing table
#             $table   - the MDB Database table
#
#  Return:  void
#
#############################################################################

sub createTableSchema
{
  my ($colsDefinition);
  my ($mdbFile,$table) = @_;
  my $mdbschema = "echo 'DESCRIBE TABLE \"$table\"' | mdb-sql ".$mdbFile;

  # Get Table Schema for the given table
  open(SCHEMA,"$mdbschema|") || die "Error Reading Table Schema: $!\n";
  while(<SCHEMA>)
  {
    chop;
    s/\s+//g;
    if(/^\|(\S+)\|(\S+)\|(\d+)\|/)
    {
      $colsDefinition .= &convertColumnType($1,$2,$3);
    }
  }
  close(SCHEMA);
  chop $colsDefinition;
  chop $colsDefinition;

  print "--\n--  Table structure for table \"$table\"\n--\n\n";

  # Drop old table data, if required
  if($opts{"d"}) {
    print "DROP TABLE IF EXISTS `$table`;\n";
  }

  # Define table's character set, if required
  if ( $opts{ "C" }) {
    print "SET CHARACTER SET ".$opts{ "C" }.";\n";
  }

  print "CREATE TABLE `$table` (\n";
  print $colsDefinition, "\n";
  print ");\n\n";
}

##########
#
#  Subroutine: convertColumnType
#
#  Description: Converts the MDB (MS Access) column data type to the
#               corresponding MySQL data type and creates the column
#               structure.
#
#  Arguments: $field - MDB Database column/field name
#             $type  - MDB Database data type
#             $size  - MDB data type size
#
#  Return:  The schema for the converted column data type.
#
#############################################################################

sub convertColumnType
{
  my ($field,$type,$size) = @_;
  my $def = " ";

  $field =~ s/[^a-zA-Z0-9_\$]/$opts{"r"}/g;

  # Column type translation array;
  my %translate = (
      "Text"            => "VARCHAR($size)",
      "Memo/Hyperlink"  => "TEXT",
      "Byte"            => "TINYINT",
      "Integer"         => "SMALLINT",
      "LongInteger"     => "INT",
      "Single"          => "DOUBLE",
      "Double"          => "DOUBLE",
      "Numeric"         => "FLOAT",
      "Currency"        => "DECIMAL(10,2)",
      "DateTime"        => "DATETIME",
      "DateTime(Short)" => "DATETIME",
      "Boolean"         => "ENUM('1','0')",
      "Bit"             => "ENUM('1','0')",
      "ReplicationID"   => "TINYBLOB",
      "OLE"             => "LONGBLOB" );

  # Translane column type
  if ( $translate{ $type }) {
    $def .= sprintf( "`%s` %s,\n", $field, $translate{ $type });
  }

  # Record invalid column type
  else {
    if( $opts{ "u" }) {
      print "??? Unknown Access/MDB Field Data Type!\n";
      print "??? Field: $field\n";
      print "??? Data Type: $type($size)\n";
      print "??? Resolution Options:\n";
      print "???   1. Change the field to a known data type within Access\n";
      print "???   2. Let MDB2MySQL use a known MySQL data type instead.\n";
      print "???      The default replacement is a 'blob' but can be\n";
      print "???      changed using the -U flag.\n";
      exit;
    }
    else {
      $def .= sprintf( "`%s` %s,\n", $field, $opts{ "U" });
    }
  }

  return $def;
}

##########
#
#  Subroutine: VERSION_MESSAGE
#
#  Description: Displays the version message.  Complies to the Getopts
#               perl module.
#
#  Arguments: none
#
#  Return:  void
#
#############################################################################

sub VERSION_MESSAGE()
{
  print $VERSION, "\n";
  print "Created By: Bill Lewis <bill\@enobis.com>\n";
  print "Updated By: Dmytro Konstantinov <ursa.dk\@icloud.com>\n";
  print "GNU General Public License (http://www.gnu.org/copyleft/gpl.html)\n";
}

##########
#
#  Subroutine: HELP_MESSAGE
#
#  Description: Displays the help message.  Complies to the Getopts
#               perl module.
#
#  Arguments: none
#
#  Return:  void
#
#############################################################################

sub HELP_MESSAGE()
{
  print "\nUsage: mdb2mysql [options] <mdb file>\n";
  print "  -c             Create table structure only, no data.\n";
  print "  -d             Add a 'drop table' before each create.\n";
  print "  -e             Use the much faster, extended INSERT syntax.\n";
  print "  -i             Export data inserts only.\n";
  print "  -l             Add locks around insert statements.\n";
  print "  -o <tables>    Omit tables in this comma seperated list.\n";
  print "  -r <character> Replace illegal characters with given character.\n";
  print "  -t <tables>    Export only this list of comma seperated tables.\n";
  print "  -u             Report unknown Access data type and exit.\n";
  print "  -x             Same as using -d -e -l combined options.\n";
  #print "  -M             Convert Access System tables ('MSys') as well.\n";
  print "  -C <type>      Define character set of the transferred data.\n";
  print "  -U <type>      Use the MySQL data type for unknown Access types.\n";
  print "                 Unless given, 'blob' will be used by default.\n";
  print "  -h, --help     This message and exit.\n";
  print "  -V, --version  Output version information and exit.\n";
}
