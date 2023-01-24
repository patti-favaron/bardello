/*

Copyright 2023 Patrizia Favaron

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR
A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import std.stdio;
import std.file;
import std.algorithm;
import std.array;
import std.conv;
import std.datetime;

import sonic;

void main(string[] args) {

    // Get input parameters and check them
    if(args.length != 3) {
        writeln("Ultrasonic anemometer pre-processor for NanoPart 2D");
        writeln();
        writeln("Usage:");
        writeln();
        writeln("  ./pre_usa <Data_Path> <Out_File>");
        writeln();
        writeln("Copyright 2023 by Patrizia Favaron");
        writeln("This is open-source code, covered by the MIT license (see https://opensource.org/licenses/MIT)");
        writeln();
        return;
    }
    string sDataPath = args[1];
    string sOutFile  = args[2];

    // Main loop: iterate over "*.DAT" files in directory
    DateTime[] tvOutDateTime;
    float[]    rvOutUm, rvOutVm, rvOutWm, rvOutTm;
    float[]    rvOutUU, rvOutVV, rvOutWW, rvOutTT;
    float[]    rvOutUT, rvOutVT, rvOutWT;
    float[]    rvOutUV, rvOutUW, rvOutVW;
    auto files = dirEntries(sDataPath, "*.DAT", SpanMode.shallow).
                    filter!(a => a.isFile()).array();
    sort!((a,b) => a.name < b.name)(files);
    foreach (string file; files)
    {

        // Inform user of progress
        write("Processing file ");
        writeln(file);

        // Gather file contents
        DateTime[] tvDateTime;
        float[]    rvUm, rvVm, rvWm, rvTm;
        float[]    rvUU, rvVV, rvWW, rvTT;
        float[]    rvUT, rvVT, rvWT;
        float[]    rvUV, rvUW, rvVW;
        DataSet tDataSet = DataSet(file);
        int iRetCode = tDataSet.stats(
            tvDateTime,
            rvUm, rvVm, rvWm, rvTm,
            rvUU, rvVV, rvWW, rvTT,
            rvUV, rvUW, rvVW,
            rvUT, rvVT, rvWT
        );
        tvOutDateTime ~= tvDateTime;
        rvOutUm       ~= rvUm;
        rvOutVm       ~= rvVm;
        rvOutWm       ~= rvWm;
        rvOutTm       ~= rvTm;
        rvOutUU       ~= rvUU;
        rvOutVV       ~= rvVV;
        rvOutWW       ~= rvWW;
        rvOutTT       ~= rvTT;
        rvOutUV       ~= rvUV;
        rvOutUW       ~= rvUW;
        rvOutVW       ~= rvVW;
        rvOutUT       ~= rvUT;
        rvOutVT       ~= rvVT;
        rvOutWT       ~= rvWT;

    }

    // Write results to output file
    auto g = File(sOutFile, "w");
    g.writeln("date,um,vm,wm,tm,uu,vv,ww,tt,uv,uw,vw,ut,vt,wt");
    for(size_t i = 0; i < tvOutDateTime.length; i++)
    {
        string sDateTime = tvOutDateTime[i].toISOExtString();
        g.writeln(
            sDateTime,
            ",",rvOutUm[i],
            ",",rvOutVm[i],
            ",",rvOutWm[i],
            ",",rvOutTm[i],
            ",",rvOutUU[i],
            ",",rvOutVV[i],
            ",",rvOutWW[i],
            ",",rvOutTT[i],
            ",",rvOutUV[i],
            ",",rvOutUW[i],
            ",",rvOutVW[i],
            ",",rvOutUT[i],
            ",",rvOutVT[i],
            ",",rvOutWT[i]
        );
    }
    g.close();

}
