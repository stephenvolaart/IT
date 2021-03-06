#!/usr/bin/env perl

#####################################
#####################################
### ______               _     =) ###
### | ___ \             | |       ###
### | |_/ / __ _  _ __  | |       ###
### |    / / _` || '_ \ | |       ###
### | |\ \| (_| || | | || |____   ###
### \_| \_|\__,_||_| |_|\_____/   ###
#####################################
#####################################

# Info
#
# Search for files gr8r than size in the svn repository

use strict;
use Getopt::Long;
Getopt::Long::Configure('bundling');
require XML::Simple;
require Math::Round;
use Data::Dumper;

## Settings
##################
my $xml = new XML::Simple;
my $svn = '/path/to/svn';
my $username = 'user';
my $password = '123456';
$svn = "$svn --no-auth-cache --username $username --password $password --trust-server-cert --non-interactive";
my $svn_list = "$svn list --xml -R";
my $printf = " %-10.10s\t%-80.80s\t%-10.10s\n";
my %results;
sub FSyntaxError($) {
	my $err = shift;
	print <<EOU;
  $err

     Syntax:
	 $0 -p [svn repository path] -s [file size (in Bytes)] --csv
	 --csv - csv format output
EOU
exit(1);
}

## Verify User Input
######################
my %opt;
my $result = GetOptions(\%opt,
	'path|p=s',
	'size|s=i',
	'csv',
);

FSyntaxError("Missing -p")  unless defined $opt{'path'};
FSyntaxError("Missing -s")  unless defined $opt{'size'};

my $test_path = `$svn info $opt{'path'} &> /dev/null ; echo \$? `; chomp($test_path);
if($test_path) {
	FSyntaxError("ERR: $opt{'path'} is not a Subversion repository\nExiting...");
	exit(1);
}

## Start Checking
####################
my $out = `$svn_list $opt{'path'}`;
my $data = $xml->XMLin($out);
my $list = $$data{'list'}{'entry'};
foreach my $key ( keys %{$list}) {
	if($$list{$key}{'kind'} ne 'file') { next ; }
	if($$list{$key}{'size'} >= $opt{'size'}) {
		$results{$key}{'size'} = $$list{$key}{'size'};
		$results{$key}{'author'} = $$list{$key}{'commit'}{'author'};
	}
}

## Print Results to screen
############################
if(%results) {
	unless ($opt{'csv'}) {
		print "######## Repo Path: $opt{'path'}\tFile Size: >= ",_byte_size($opt{'size'})," ########\n";
		printf($printf,"Author","File Name","Size");
		print "*----------------------------------------------------------------------------------------------------------------*\n";
		foreach my $key ( sort keys %results) {
			printf($printf,$results{$key}{'author'},$key,_byte_size($results{$key}{'size'}));
		}
	} else {
		print "Repo Path,$opt{'path'}\n";
		print "File Size: >= ,",_byte_size($opt{'size'}),"\n";
		print "Author,File Name,Size\n";
		foreach my $key ( sort keys %results) {
			print "$results{$key}{'author'},$key,",_byte_size($results{$key}{'size'}),"\n";
		}
	}
} else {
	print "Can't find files >= ",_byte_size($opt{'size'}),"\n";
	exit(1);
}
