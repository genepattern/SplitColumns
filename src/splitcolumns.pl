#!/usr/bin/perl
use Getopt::Long;

my $result = GetOptions ("i:s" => \$inputFile,
                         "o:s"   => \$outputPrefix,
                         "c:s"   => \$columns,
                         "a:s"   => \$additionalColumns
                         );

#check required input parameters
if ($inputFile eq "") {
	print STDERR "ERROR: An input file must be specified\n";
	exit(1);
}

if ($outputPrefix eq "") {
	print STDERR "ERROR: An output prefix must be specified\n";
	exit(1);
}


if(!(-T $inputFile))
{
    print STDERR "ERROR: The input file must be a text file\n";
    exit(1);
}

# find out number of columns in the input file
open FILE, "<", $inputFile or die $!;
my $line = <FILE>;
chomp $line;
@line_items = split('\t', $line);
$num_col_items = @line_items;

if($num_col_items < 1)
{
    print STDERR "An error occurred while obtaining the number of columns in the input file. Please check that the input file is tab delimited.";
    exit(1);
}
close(FILE);


if ($columns ne "")
{
    @selected_columns = parseColumnString($columns);
}
else
{
    @selected_columns = (1 .. $num_col_items);
}

$num_selected_columns = @selected_column;
print "\nThe selected split columns were: @selected_columns\n";


$num_additional_cols = 0;
if ($additionalColumns ne "")
{
    @additional_columns = parseColumnString($additionalColumns);
    $num_additional_cols = @additional_columns;

    print "\nThe selected additional columns to include were: @additional_columns\n";
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
    foreach $scol (@selected_columns)
    {
        if($scol > $num_col_items)
        {
            print STDERR "$scol is greater than number of columns in input file $num_col_items";
            exit(1);
        }

        $outputFile = $outputPrefix."_".$scol.".splitcol.txt";

        $cutString = $scol;
        #if additional columns should be included then do this now
        if($num_additional_cols > 0)
        {
            @cut_columns = @additional_columns;
            push(@cut_columns, $scol);
            @cut_columns = sort(@cut_columns);
            $cutString = join(",", @cut_columns);
        }
        system("cut -f$cutString $inputFile > $outputFile");
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

        foreach $scol (@selected_columns)
        {
	        if($scol > $num_col_items)
	        {
		        print STDERR "$scol is greater than number of columns in input file $num_col_items";
		        exit(1);
	        }

            $outputFile = $outputPrefix."_".$scol.".splitcol.txt";
            open OFILE, ">>", $outputFile or die $!;

            #if additional columns should be included then do this now
            if($num_additional_cols > 0)
            {
                @cut_columns = @additional_columns;
                push(@cut_columns, $scol);
                @cut_columns = sort(@cut_columns);
                foreach $dcol (@cut_columns)
                {
                    print OFILE $line_items[$dcol-1]."\n";
                }
            }
            else
            {
                print OFILE $line_items[$scol-1]."\n";
            }
            close (OFILE);
        }
    }

    close(FILE);
}

sub parseColumnString
{
    $colString = shift;
    my @columnsArray;
    if ($colString ne "")
    {
        @column_split = split(',', $colString);

        #loop through comma separated column string
        foreach $col (@column_split)
        {
            if(rindex($col, "-") != -1)
            {
                @col_range = split('-', $col);

                #check that the range found is valid, only contains a start and end value
                $num_col_range = @col_range;
                if($num_col_range < 1)
                {
                    print STDERR "\nAn error occurred while parsing the column(s) specified: ".$colString;
                    exit(1);
                }

                #user only specified start, in this we case we output all columns after start
                if($num_col_range == 1)
                {
                    $end = $num_col_items;
                }
                else
                {
                    $end = $col_range[1];
                }

                $start = $col_range[0];
                if($start > $end)
                {
                    $temp = $start;
                    $start = $end;
                    $end = $temp;
                }

                @col_num_range = ($start .. $end);
                @columnsArray = (@columnsArray, @col_num_range);
            }
      	    else
      	    {
    	        push(@columnsArray, trim($col));
      	    }
        }
    }

    return @columnsArray;
}
# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

