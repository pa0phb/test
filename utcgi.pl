#!/usr/bin/perl
# ********************************************************
# utcgi.pl
# ********************************************************
# set met algemene routines
#
#  %query = &cgiparse();
#  %QUERY = &CGIPARSE();     For parameters in UPPERCASE
#  $datestring = timetostr(utc);
#  url_decode en url_encode van query strings
#
# Subroutine cgiparse parses the contents 
# of a CGI query into an associative array.
# 
# version 2.0 datum 2015/08/29
# added ReadFile en WriteFile
# ********************************************************

1;
# ********************************************************
# Extract parameters into hash %PARMS
sub CGIPARSE {
# COnvert parameter names to UPPERCASE

   local(%parms)=&cgiparse();
   foreach $parm (keys %parms) {
      ($PARM = $parm) =~ tr/a-z/A-Z/;
      $PARMS{$PARM}=$parms{$parm};
   }
   %PARMS;
}

sub cgiparse {

    local ($data) = shift;

    # Fetch the data for this request.

    if ( defined $data ) {
        # We have data passed
    } elsif ($ENV{'REQUEST_URI'} =~ /\?(.*)$/) {
        # data as parm/value pair attached to htm-file
        $data = $1;

    } elsif ( $ENV{'REQUEST_METHOD'} eq 'POST' ) {
        # Read it from standard input.
        local ($len) = $ENV{'CONTENT_LENGTH'};
        if ( read (STDIN, $data, $len) != $len ) {
            die ("CGI_Error reading 'POST' data\n");
        }
    } else {
        # Fetch from environment variable.
        $data = ($ENV{'QUERY_STRING'}) ? $ENV{'QUERY_STRING'} :$ENV{'QUERY_STRING_UNESCAPED'};
    }

    # The data is encoded as name1=val1&name2=val2&etc.
    local (%qs);           # resultant hash array
    # First split on name/value pairs.
    foreach $qs ( split (/\&/, $data) ) {
        # Then split name and value.
        local ($name, $val) = split (/=/, $qs);
        # URL decode and put in resultant hash array.
        $name = &url_decode ($name);
        if ( defined $qs{$name} ) {
            # Multiple values. Append using \0 separator.
            $qs{$name} .= "\0" . &url_decode ($val);
        }
        else {
            # Store it.
            $qs{$name} = &url_decode ($val);
        }
    }

    # And return it.
    return %qs;
}


# ********************************************************
# Convert current date/time to a neat string.
sub timetostr {
    local ($t) = shift;
    local ($result) = scalar($t);

    require 'ctime.pl';
    local $result = &ctime($t);
    return result.

}

# ********************************************************
# Subroutines to handle basic decoding of URL data.
sub url_decode {
# Webmasters handboek pag 45
    local ($s) = @_;

    # Translate + to space, and %XX to the character code.

    $s =~ tr/+/ /;
    $s =~ s/%([0-9A-F][0-9A-F])/pack("C",oct("0x$1"))/ge;
    $s;
}

sub UTCGIGetHost {
   local($host) = shift;
   local($h,$lookup,@d);
   if (open(X,"/usr/bin/host $host |")) {
      $lookup = join('',<X>);
      close(X);
      @d = split(/\s/,$lookup);
      $h = pop(@d);
      if ($h) {
         ### $host = "($host|$h)";
         $lookup = "($host|$h)";
      }
   } else {
      $lookup = 'Host-lookup not executed.';
   }
   return($host, $lookup);
}

sub UTCGITODAY {
    return &UTCGIToday(shift);
}
    
sub UTCGIToday {
   local $utc = shift || time;
   local @d = localtime($utc);
   return sprintf("%4d%02d%02d",$d[5]+1900,$d[4]+1,$d[3]);
}      

sub UTCGIMutad {
   # convert date code or text to mutad
   local($txt)=shift;
   if ($txt =~ /^\s*$/) {
      @d=localtime(time);
   } elsif ($txt =~ /(\d{10})/) {
      @d=localtime($1);
   } else {
      return $txt;
   }

   return(sprintf("%4d%02d%02d",$d[5]+1900,$d[4]+1,$d[3]));
}

sub UTCGITime2Mutad {return UTCGIMutad($_);}

# ***********************************************
# convert mutad naar timecode
sub UTCGIMutad2time {
    
	local($mutad)=shift;
	return 0 unless ($mutad>0);
	$mutad =~ /(\d\d\d\d)(\d\d)(\d\d)/;
	return (timelocal(0,0,0,$3,$2-1,$1-1900));
}

sub UTCGIDatum {
# Conversie mutad naar datum
	my $mutad = shift;
	my $option= shift; # als er iets is ingevuld dan verkorte maand aanduiding
	my @MAAND = qw(januari februari maart april mei juni juli augustus september oktober november december);
	
	return "Fout format [yyyymmdd]" unless ($mutad =~ /(\d\d\d\d)(\d\d)(\d\d)/);
	return sprintf("%d %s %4d",$3,$MAAND[$2-1],$1);
} 
	

# *******************************************************
sub UTCGIPARMS {
   # Show CGI-parameters
   print "\nParameters (utcgi.pl) <br>\n"; 
   foreach $key (sort keys %PARMS) {
      print "<br>- $key =$PARMS{$key}";
   }
   print "<br>===\n";
}

# *******************************************************
sub UTCGIShowEnv {
# Meldt alle environment parameters
	my $txt = "<p>ENVIRONMENT \n";
	foreach $key (sort keys %ENV){
		$txt .= "<br>$key = $ENV{$key}\n";
	}
	return "$txt</p>\n";
}

# *******************************************************
sub UTCGIShowParms { 
# Meldt alle invoer parameters
	my %parms = @_ || %PARMS;
	my $txt = "<p>PARAMETERS \n";   
   foreach $parameter (sort keys %parms) {
      $txt .= "$parameter = $PARMS{$parameter}\n";
   }
   return "$txt</p>\n";
}

# ********************************************
# verwijder leading en trailing spaties
sub trim {
   local($txt)=shift;
   $txt=~ s/^\s+//;
   $txt =~ s/\s*$//s;
   return $txt;
}

# ********************************************
# Zet komma om in punt (Financien)
sub UTCGIFP{
   # Zet komma om in punt
   local $getal = shift;
   local $format = shift;
}



# ********************************************
# Read  File with checks
# Returns content or error message
sub ReadFile {
   local $file = shift;
   local $err = '';
   local @inhoud;

   unless (-e $file) {
      $err = "Bestand [$file] bestaat niet\n";
      return $err;
   }
   unless (-r $file) {
      $err = "Bestand [$file] niet leesbaar\n";
      return $err;
   }
   open(Z,$file);
   @inhoud = <Z>;
   close(Z);
   return @inhoud;
}

# ********************************************
# Write  File with checks
# Returns mod-time and size or error message
sub WriteFile {
   local $file = shift;
   local $txt  = shift;
   local $force= shift;
   local $err = '';

   unless (($force) && (-e $file )) {
	 return "[$file] bestaat\n";
   }

   unless (-w $file) {
      return "[$file] is niet schrijfbaar\n"
   }

   open(F,">$file");
   print F $txt;
   close(F);

   local @s = stat($file);
   local $size = $s[7];
   local $mtime= &UTCGIMUTAD($s[9]);
   
   return "[$file] modified=$mtime, size=$size\n"; 

}
