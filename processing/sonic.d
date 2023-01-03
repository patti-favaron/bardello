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

module sonic;

import std.stdio;
import std.file;
import std.datetime;
import std.array;
import std.conv;
import std.math;
import std.string;

struct DataSet {

    // Data
    DateTime[] tvTimeStamp;
    float[]    rvU;
    float[]    rvV;
    float[]    rvW;
    float[]    rvT;


    // Read constructor
    this(string sFileName) {

        auto f = File(sFileName, "r");
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
                string sU = strip(svFields[1][15..21]);
                string sV = strip(svFields[1][ 5..11]);
                string sW = strip(svFields[1][25..31]);
                string sT = strip(svFields[1][35..41]);
                if(sU.empty || sV.empty || sW.empty || sT.empty) {
                    continue;
                }
                float rU = to!int(sU) / 100.0;
                float rV = to!int(sV) / 100.0;
                float rW = to!int(sW) / 100.0;
                float rT = to!int(sT) / 100.0;
                rvU ~= rU;
                rvV ~= rV;
                rvW ~= rW;
                rvT ~= rT;

            }
        }
    }


    int stats(
        out DateTime[] date_time,
        out float[] um, out float[] vm, out float[] wm, out float[] tm,
        out float[] uu, out float[] vv, out float[] ww, out float[] tt,
        out float[] uv, out float[] uw, out float[] vw,
        out float[] ut, out float[] vt, out float[] wt
    ) {

        // Assume success (will falsify on failure)
        int iRetCode = 0;

        // Check the data set contains something
        if(this.tvTimeStamp.length <= 0)
        {
            iRetCode = 1;
            return iRetCode;
        }

        // Compute minimum and maximum time stamps, and deduce array sizes from them. Because
        // of the way data are time-stamped, with no possibility to alter the RTC by users or
        // external systems, we can give for granted time stamps are monotonically non-decreasing.
        // Minimum and maximum time stamps are then the ones of first and last data items.
        auto min_time = this.tvTimeStamp[0];
        auto last_index = this.tvTimeStamp.length - 1;
        auto max_time = this.tvTimeStamp[last_index];
        Duration time_delta = max_time - min_time;
        long max_index = time_delta.total!"seconds";

        // Compute non-rotated statistics
        size_t[] block = this.begin_end_seconds();
        for(size_t i = 0; i < block.length-1; i++)
        {
            date_time ~= this.tvTimeStamp[block[i]];
            um        ~= this.mean(block[i],block[i+1], this.rvU);
            vm        ~= this.mean(block[i],block[i+1], this.rvV);
            wm        ~= this.mean(block[i],block[i+1], this.rvW);
            tm        ~= this.mean(block[i],block[i+1], this.rvT);
            uu        ~= this.cov(block[i],block[i+1], this.rvU, this.rvU);
            vv        ~= this.cov(block[i],block[i+1], this.rvV, this.rvV);
            ww        ~= this.cov(block[i],block[i+1], this.rvW, this.rvW);
            tt        ~= this.cov(block[i],block[i+1], this.rvT, this.rvT);
            uv        ~= this.cov(block[i],block[i+1], this.rvU, this.rvV);
            uw        ~= this.cov(block[i],block[i+1], this.rvU, this.rvW);
            vw        ~= this.cov(block[i],block[i+1], this.rvV, this.rvW);
            ut        ~= this.cov(block[i],block[i+1], this.rvU, this.rvT);
            vt        ~= this.cov(block[i],block[i+1], this.rvV, this.rvT);
            wt        ~= this.cov(block[i],block[i+1], this.rvW, this.rvT);
        }

        // Leave
        return iRetCode;

    }


    // Identify all points in a seconds time vector at which changes occur
    private size_t[] begin_end_seconds() {
        size_t[] ivChangeIndex = [0];
        for(size_t i=1; i<this.tvTimeStamp.length; i++)
        {
            if(this.tvTimeStamp[i] != this.tvTimeStamp[i-1])
            {
                ivChangeIndex ~= i;
            }
        }
        ivChangeIndex ~= this.tvTimeStamp.length;
        return ivChangeIndex;
    }


    private float mean(size_t iBegin, size_t iEnd, float[] data)
    {
        long  iNumData = iEnd - iBegin;
        if(iNumData < 0)
        {
            return NaN(0);
        }
        float rAvg = 0.0;
        for(size_t i = iBegin; i < iEnd; i++)
        {
            rAvg += data[i];
        }
        rAvg /= iNumData;
        return rAvg;
    }
    

    private float cov(size_t iBegin, size_t iEnd, float[] data1, float[] data2)
    {
        long  iNumData = iEnd - iBegin;
        if(iNumData < 0)
        {
            return NaN(0);
        }
        float rAvg1 = 0.0;
        float rAvg2 = 0.0;
        for(size_t i = iBegin; i < iEnd; i++)
        {
            rAvg1 += data1[i];
            rAvg2 += data2[i];
        }
        rAvg1 /= iNumData;
        rAvg2 /= iNumData;
        float rCov = 0.0;
        for(size_t i = iBegin; i < iEnd; i++)
        {
            rCov += (data1[i]-rAvg1) * (data2[i]-rAvg2);
        }
        rCov /= iNumData;
        return rCov;
    }
    
}
