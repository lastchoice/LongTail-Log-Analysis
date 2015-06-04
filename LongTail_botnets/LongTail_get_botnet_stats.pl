#!/usr/bin/perl

############################################################################
## adds commas to numbers so they are readable
## 
sub commify {
	my ( $sign, $int, $frac ) = ( $_[0] =~ /^([+-]?)(\d*)(.*)/ );
	my $commified = (
	reverse scalar join ',',
	unpack '(A3)*',
	scalar reverse $int
	);
	return $sign . $commified . $frac;
}     

sub remove_single_attempts_from_sum2 {
	open (SUMDATA, "/var/www/html/honey/attacks/sum2.data");	
	open (SUMDATA_OUT, ">/var/www/html/honey/attacks/sum2.data_large_attacks");	
	while (<SUMDATA>){
		($dict,$attack)=split(/  /,$_);
		$wc = `cat /var/www/html/honey/attacks/dict-$dict.txt.wc`;
		chomp $wc;
		if ($wc > 5){
			print (SUMDATA_OUT $_);
		}
	}
	close (SUMDATA);
	close (SUMDATA_OUT);
}


sub init {
	$|=1;
	chdir ("/usr/local/etc/LongTail_botnets");
	$client_data="/var/www/html/honey/clients.data /var/www/html/honey/kippo_clients.data";
	$this_year=`date +%Y`;
	chomp $this_year;
	$this_month=`date +%m`;
	chomp $this_month;
	$this_day=`date +%d`;
	chomp $this_day;
}

sub print_header {
	print "<!--#include virtual=\"/honey/header.html\" -->\n";
	print "<H3>BotNet Analysis</H3>\n";
	print "<P>BotNet analysis under development.  Botnets shown are.\n";
	print "smaller than shown here due to a small bug in the code which\n";
	print "being fixed shortly.\n";
	print "\n";
	print "<P>These numbers are based on \"Attack Patterns\", which are \n";
	print "generated 4 times a day, so these numbers will not match\n";
	print "what is on the front page of LongTail.\n";
	print "<P>Here's a preview of some of what is coming \n";
	$date=`date`;
	print "Created on $date\n";
	if ( ! -e "/var/www/html/honey/attacks/sum2.data"){
		print "<P>Attack patterns being generated now, please check back later\n";
	}
}

sub pass_1 {
	open (FIND, "find . -type f -print|sort |") || die "Can not run find command\n";
	$number_of_botnets=0;
	$global_max=0;
	$global_min=99999;
	$global_total=0;
	while (<FIND>){
		chomp;
	#print "Found filename $_\n";
		if (/.sh$/){next;}
		if (/.pl$/){next;}
		if (/.html/){next;}
		if (/.shtml/){next;}
		if (/typescript/){next;}
		if (/2015/){next;}
		if (/backups/){next;}
	#	if (! /small_bots_2/){next;}
	#print "proceeding with filename $_\n";
		$filename=$_;
		$filename=~ s/\.\///;
		#print "Looking for botnet $filename\n";
		print "<H3>BotNet $filename</H3>\n";
		print "<P>Hosts involved with $filename are:\n<BR>\n";
		$total=0;
		$total_year=0;
		$total_month=0;
		$total_day=0;
		$attacks=0;
		$min=999999999;
		$max=0;
		open (FILE, "$_");
		unlink ("/tmp/TAG");
		`echo \"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\" > /tmp/TAG`;
		$number_of_bots=0;
		$number_of_botnets++;
		while (<FILE>){
			chomp;
			$ip=$_;
			if (/\.\.\./){next;}
			$number_of_bots++;
			print "$ip ";
			if ($ips_seen_already{$ip}){
				print "<BR>$ip has already been seen in $ips_seen_already{$ip}\n<BR>\n";
				$ips_seen_already{$ip}=$ips_seen_already{$ip}." ".$filename;
			}
			else {
				$ips_seen_already{$ip}=$filename;
			}
			open (SUMDATA, "/var/www/html/honey/attacks/sum2.data");	
			while (<SUMDATA>){
				if (/$ip/){
					($dict,$attack)=split(/ /,$_,2);
					#/var/www/html/honey/attacks/218.25.54.51.shepherd.1-2015.05.04.12.53.19-04
					($trash,$date)=split(/-/,$attack);
					$wc=`cat /var/www/html/honey/attacks/dict-$dict.txt.wc`;
					# These are patterns to search for from other IP addresses
					if ($wc > 3){
						`echo $dict >>/tmp/TAG`;
					}
					#print "$wc ";
					if ($attack =~ "$this_year"){$total_year+=$wc;}
					if ($attack =~ "$this_year.$this_month"){$total_month+=$wc;}
					if ($attack =~ "$this_year.$this_month.$this_day"){$total_day+=$wc;}
					chomp $wc;
					if ( $wc > $max){$max=$wc;}
					if ( $wc < $min){$min=$wc;}
					if ( $wc > $global_max){$global_max=$wc;}
					if ( $wc < $global_min){$global_min=$wc;}
					$total+=$wc;
					$global_total+=$wc;
					$attacks++;
					$global_attacks++;
				}
			}
			close (SUMDATA);
		}
		close (FILE);
		`sort /tmp/TAG |uniq >/tmp/TAG.2`;
		#
		# This is where we find similar patterns to what we have
		# found already
		#
		# The statistics for these new hosts will show up the next 
		# time this program is run.
		#
		# Yes, I could make this recursive but I won't because
		# I don't want some weird recursive loop going on forever
		# until I just happen to catch it.
	
#		print "New matching patterns are:\n";
#		$TMP=`for pattern in \`cat /tmp/TAG.2\` ; do grep -F \$pattern /var/www/html/honey/attacks/sum2.data_large_attacks; done`;
#		print $TMP;
#		print "\n";
		`for pattern in \`cat /tmp/TAG.2\` ; do grep -F \$pattern /var/www/html/honey/attacks/sum2.data_large_attacks; done  |awk '{print \$2}' |sed 's/-..*//'  | awk -F\. '{print \$1,\$2,\$3,\$4}' |sed 's/ /./g' |sort |uniq >/tmp/tag.3`;
	
	
		$DATE= `date +%Y.%m.%d:%H.%M`;
		`cp $filename $filename.$DATE`;
		`cat /tmp/tag.3 >> $filename`;
		`sort -u $filename >> $filename.2`;
		`cp  $filename.2  $filename`;
		`rm $filename.2`;
		unlink("/tmp/TAG.2");
		unlink ("/tmp/tag.3");
	
		print "\n";
		$output=`for ip in \`cat $filename\` ; do grep \$ip $client_data; done`;
		$output =~ s/\n/\n<BR>/g;
		$output =~ s/\/var\/www\/html\/honey\///g;
		print "<P>Client software and level:\n<BR>\n";
		print $output;
		if ($attacks>0){
			$average=$total/$attacks;
		}
		else {
			$average=0;
		}
		$average=sprintf("%.2f",$average);
		$average=&commify($average);
		$total=&commify($total);
		$total_year=&commify($total_year);
		$total_month=&commify($total_month);
		$total_day=&commify($total_day);
		$number_of_bots=&commify($number_of_bots);
		$min=&commify($min);
		$max=&commify($max);
		print "\n<BR>\n<P>Total ssh attempts from $filename since logging began: $total\n";
		print "<P>Total ssh attempts from $filename this year: $total_year\n";
		print "<P>Total ssh attempts from $filename this month: $total_month\n";
		print "<P>Total ssh attempts from $filename today: $total_day\n";
		print "<P>Total number of bots in $filename: $number_of_bots\n";
		print "<P>Minimum attack size from $filename: $min\n";
		print "<P>Average attack size from $filename: $average\n";
		print "<P>Maximum attack size from $filename: $max\n";
		$total=0;
		$total_year=0;
		$total_month=0;
	}
	close (FIND);
}

sub print_footer {
	if ($global_attacks>0){
		$average=$global_total/$global_attacks;
	}
	else {
		$average=0;
	}
	$average=sprintf("%.2f",$average);
	$average=&commify($average);
	$global_average=sprintf("%.2f",$global_average);
	$global_average=&commify($global_average);
	$global_total=&commify($global_total);
	$global_min=&commify($global_min);
	$global_max=&commify($global_max);
	print "<H3>BotNet Totals</H3>\n";
	#print "<P>Total ssh attempts from all BotNets since logging began: $global_total\n";
	print "<P>Total number of botnets known: $number_of_botnets\n";
	print "<P>Minimum attack size from all BotNets: $global_min\n";
	print "<P>Average attack size from all BotNets: $average\n";
	print "<P>Maximum attack size from all BotNets: $global_max\n";

	print "<!--#include virtual=\"/honey/footer.html\" -->\n";
}

&init ;
&remove_single_attempts_from_sum2 ;
&print_header ;
&pass_1 ;
&print_footer ;

