#!/usr/bin/perl
use Getopt::Long;

my $result = GetOptions ("i:s" => \$inputFile,
                         "o:s"   => \$outputPrefix,
                         "c:s"   => \$columns,
                         "s:s"   => \$numskip
                         );

#check required input parameters
if ($inputFile eq "") {
	print STDERR "An input file must be specified\n";
	exit(1);
}

if ($outputPrefix eq "") {
	print STDERR "An output prefix must be specified\n";
	exit(1);
}

$extension = ($inputFile =~ m/([^.]+)$/)[0];

@selected_columns;

if ($columns ne "")
{
    @column_split = split(',', $columns);

    #loop through comma separated column string
    foreach $col (@column_split)
    {
        if(rindex($col, "-") != -1)
        {
            @col_range = split('-', $col);

            #check that the range found is valid, only contains a start and end value
            $col1_range = @col_range;
            if($col1_range != 2)
            {
                print STDERR "\nAn error occurred while parsing the column(s) specified: ".$columns;
                exit(1);
            }

            $start = $col_range[0];
            $end = $col_range[1];
            if($start > $end)
            {
                $start = $col_range[1];
                $end = $col_range[0];
            }

            @col_num_range = ($start .. $end);
            @selected_columns = (@selected_columns, @col_num_range);
        }
  	else
  	{
	    push(@selected_columns, trim($col));
  	}
    }
    print "The selected columns were: @selected_columns\n";
}
else
{
    print "All columns were selected\n";
}

if(cutCommandExists() eq "false")
{
    runSplitDataPerl();
}
else
{
    runCutCommand();
}

sub cutCommandExists
{
    #check if cut command exists
    open(CPERR, '>&STDERR');

    open(STDERR, '>/dev/null')|| die "Error stderr: $!";

    $cut_exec_result = system("cut");

    close(STDERR) || die "Can't close STDERR: $!";

    open(STDERR, ">&CPERR") || die "Can't restore stderr: $!";

    print "cut exit code: $cut_exec_result";
    #check exit code
    if($cut_exec_result != -1)
    {
        return 'true';
    }
    else
    {
        return 'false';
    }

}
sub runCutCommand
{
    $num_selected_columns = @selected_column;

    # find out number of columns in the input file
    open FILE, "<", $inputFile or die $!;
    my $line = <FILE>;
    chomp $line;
    @line_items = split('\t', $line);
    $num_line_items = @line_items;
    
    if($num_line_items < 1)
    {
	print STDERR "An error occurred while obtaining the number of columns in the input file. Please check t\
hat the input file is tab delimited.";
	exit(1);
    }

    close(FILE);
    if(!(defined @selected_columns || $num_selected_columns > 0))
    {
	$num_line_items = @line_items;
        if($num_line_items < 1)
        {
            print STDERR "An error occurred while obtaining the number of columns in the input file. Please check that the input file is tab delimited.";
            exit(1);
        }

        @selected_columns = (1 .. $num_line_items);
    }

    foreach $scol (@selected_columns)
    {
	if($scol > $num_line_items)
	{
	    print STDERR "$scol is greater than number of columns in input file $num_line_items";
	    exit(1);
	}

	$outputFile = $outputPrefix."_".$scol.".".$extension;

	system("cut -f$scol $inputFile > $outputFile");
    }
}

sub runSplitDataPerl
{
    open FILE, "<", $inputFile or die $!;

    $count = 0;
    $num_selected_columns = @selected_column;
    #open the input file
    while (my $line = <FILE>)
    {
        chomp $line;
        @line_items = split('\t', $line);

	if($count == 0)
	{
	    $num_line_items = @line_items;
	    if($num_line_items < 1)
            {
                print STDERR "An error occurred while obtaining the number of columns in the input file. Please check that the input file is tab delimited.";
                exit(1);
            }
	    $count = $count +1;
	}

        if(!(defined @selected_columns || $num_selected_columns > 0))
        {
            @selected_columns = (1 .. $num_line_items);

            $num_selected_columns = @selected_columns;

            print "\nSelected columns: @selected_columns\n";
        }

        foreach $scol (@selected_columns)
        {
	    if($scol > $num_line_items)
	    {
		print STDERR "$scol is greater than number of columns in input file $num_line_items";
		exit(1);
	    }

            $outputFile = $outputPrefix."_".$scol.".".$extension;
            open OFILE, ">>", $outputFile or die $!;
            print OFILE $line_items[$scol-1]."\n";
            close (OFILE);
        }
    }

    close(FILE);
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

