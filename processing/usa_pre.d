import std.stdio;
import std.file;
import std.algorithm;
import std.array;
import std.exception;
import std.datetime;
import std.conv;

void main(string[] args) {

    // Get input parameters and check them
    if(args.length != 3) {
        writeln("Ultrasonic anemometer pre-processor for NanoPart 2D");
        writeln();
        writeln("Usage:");
        writeln();
        writeln("  ./pre_usa <Data_Path> <Out_File>");
        writeln();
        writeln("Copyright 2022 by Patrizia Favaron");
        writeln("This is open-source code, covered by the MIT license");
        writeln();
        return;
    }
    string sDataPath = args[1];
    string sOutFile  = args[2];

    // Main loop: iterate over "*.DAT" files in directory
    auto files = dirEntries(sDataPath, "*.DAT", SpanMode.shallow).
                    filter!(a => a.isFile()).array();
    sort!((a,b) => a.name < b.name)(files);
    foreach (string file; files)
    {

        // Inform user of progress
        write("Processing file ");
        writeln(file);

        // Gather file contents
        DateTime[] tvTimeStamp;
        float[]    rvU;
        float[]    rvV;
        float[]    rvW;
        float[]    rvT;
        auto f = File(file, "r");
        string sLine;
        while ((sLine=f.readln()) !is null)
        {

            // Check line is not a header, then parse it; the conition of "not being a header"
            // is equivalent to having the string part before "," being an ISO date-time, with
            // a length of 19 characters - actually I check just this
            string[] svFields = sLine.split(",");
            if(svFields[0].length == 19 && svFields[1].length == 43)
            {

                // Parse first string to date and time
                DateTime tTimeStamp = DateTime.fromISOExtString(svFields[0].replace(' ','T'));
                tvTimeStamp ~= tTimeStamp;

                // Parse sonic quadruple from second string
                float rV = to!int(svFields[1][ 6..10]) / 100.0;
                float rU = to!int(svFields[1][16..20]) / 100.0;
                float rW = to!int(svFields[1][26..30]) / 100.0;
                float rT = to!int(svFields[1][36..40]) / 100.0;
                rvU ~= rU;
                rvV ~= rV;
                rvW ~= rW;
                rvT ~= rT;

            }
        }

        writeln(tvTimeStamp.length);

    }
}
