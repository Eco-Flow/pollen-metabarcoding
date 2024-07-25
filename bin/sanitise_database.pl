#!/usr/bin/perl
use strict;
use warnings;

die "Please specify file or path to file with database in fasta\n" unless(@ARGV==1);

my $Database = $ARGV[0]; 
open(my $DB, "<", $Database)   or die "Could not open $Database \n";

my $outhandle="$Database\.corrected.tab";
open(my $OUT, ">", $outhandle)   or die "Could not open $outhandle\n";

my $firstline=0;

while (my $line=<$DB>){
	chomp $line;
	if ($line =~ m/^>/){
		if ($firstline){
			print $OUT "\n";
		}
		else{
			#do not print a newline for first line;
			$firstline=1;
		}

		my @sp0=split("\=", $line);
		my $fastaname=$sp0[0];
		my @sp1=split("\,", $sp0[1]);
		my %hash;
		foreach my $bit (@sp1){
			my @sp2=split("\:", $bit);
			$hash{$sp2[0]}=$sp2[1];
		}
		my @expected_classes=('k','p','c','o','f','g','s');
		print $OUT "$fastaname=";
		my @new_classes;
		for my $classes (@expected_classes){
			if ($hash{$classes}){
				push (@new_classes, "$classes\:$hash{$classes}");
				#print $OUT "$classes\:$hash{$classes}\,";
			}
			else{
				push (@new_classes, "$classes\:null");
				#print $OUT "$classes\:null,";
			}
		}

		my $join_class=join("\,", @new_classes);

		print $OUT "$join_class\n";

	}
	else{
		#add rest of fasta line
		print $OUT "$line";
	}
	
}
