#!/usr/local/bin/perl
print "Sending mail\n";
open (MAIL, "|/usr/bin/mailx -t") or print "cannot open mail pipe\n";
print MAIL <<RESULT;
From: RH Map Server <rgd.data\@mcw.edu>
To: dli\@mcw.edu
Subject: RH placement map


Thank you for using the rat RH map server. 
The process took the server computing time seconds.

Here is the summary report:


To find more details and placement maps, go to


Some browsers do not properly activate the entire URL above (due to
the insertion of a linefeed).  To insure access to your results 
make sure that the ENTIRE URL is copied into the browser "site" textbox.

Please note:
Your results will be kept for ONLY 3 days after , 
then deleted automatically. You may also delete all results at any time  
through our on-line system (use the URL above).

If you have any question, please feel free to contact us.

Bioinformatics Research Center
Medical College of Wisconsin
414-456-7500
RESULT
close(MAIL);
print "Finished sending mail\n";
