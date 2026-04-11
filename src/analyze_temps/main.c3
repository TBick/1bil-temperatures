module main;

import std::io;
import std::io::file;
import std::time::clock;
import std::core::ascii;
import std::core::mem;

//  TODO
//    We are going to test reading and parsing lines in a single Thread
//    Need to establish performance metrics
//    Read lines and parse
//    Perform analysis on data as we parse
//    Output analysis
//    Output performance metrics

//    Things I need to read the standard library
//      Timing mechanisms (std::time?)
//      Buffers, Readers, Streams
//      std.math -> analysis
//      Considerations for 1Billion lines of text
//        Cant hold the whole file in RAM (assumption) DO NOT TRY TO
//      Error Handling in the case of failure 
//        THERE WILL BE MANY FAILURES

//    Future considerations when exploring multithreading:
//      Concurrency VS Parallelism
//      Abstracting things into separate module or file before multi-threading
//      Argument Parsing and Handling (minimal at first)
//      Collaborate into Git/Github if necessary

const int READ_BUF_SIZE = 1024 * 1024;
const String DEFAULT_PROJECT_ROOT_INPUT = "resources/generated_temperatures.txt";
const String DEFAULT_BUILD_DIR_INPUT = "../resources/generated_temperatures.txt";




struct Analysis {
  char[4] min_station_buffer;
  ulong min_station_length;
  int min;

  char[4] max_station_buffer;
  ulong max_station_length;
  int max;

  long avg;

  long total;
  long lines_read;
}




fn int main(String[] args) {

		io::printn("\n===PROGRAM START===\n");

  Clock clock_start = clock::now();
  String input_path = args.len > 1 ? args[1] : "";
  
  Analysis analysis = {};
  analysis.min_station_length = 0;
  analysis.min = int.max;
  analysis.max_station_length = 0;
  analysis.max = int.min;
  analysis.total = 0;
  analysis.lines_read = 0;

  io::printn("  Parsing Text");
  if(catch error = parse_text(&analysis, input_path)) {
    io::printfn(" parse_text failed: %s", error);
    return 1;
  }

  NanoDuration end = clock::now() - clock_start;
  double secs = end.to_sec();
  io::printfn("%.15f seconds elapsed.", secs);

  io::printn("\n===PROGRAM END===\n");
	return 0;
}






fn void? parse_text(Analysis *analysis, String input_path) {

  //  Open File
  File text = open_input_file(input_path)!;
  defer (void)text.close();

  //  Initialize heap read buffer
  char[] read_buffer = mem::alloc_array(char, READ_BUF_SIZE);
  defer mem::free(read_buffer);
  usz carry = 0;



  // Continuous loop for EACH READ
  while(true) {
    
    //  Read bytes into read buffer
    usz bytes_read = text.read(read_buffer[carry..])!;

    //  Variables to reset every new file read
    bool eof = bytes_read == 0;
    usz filled = carry + bytes_read; //Total readable char in buffer
    usz i = 0; // Index to keep track of where we are in buff
    usz line_start_i = 0;

    if (filled == 0) break;

    // LOGIC
    //  If we hit a ';', mark by recording index
    //  If we hit a newline, we should have a marked ';' to parse
    //  Parse the line
    
    //  Loops after every line parse
    while ( i < filled) {

      usz semicolon_i = 0;  // Index for semicolon
      usz decimal_i = 0;    // Decimal index
      usz nl_i = 0;         // Newline index
      int sign = 0;         // Positive is 0, negative is 1

      // Loops until finding a ';'
      while (i < filled && read_buffer[i] != ';') {i++;}
      if (i == filled) break; // Unparsed Line - handle carry
      semicolon_i = i++;  // Increment i to start the next character

      //  Grab sign polarity
      if ( read_buffer[i] == '-') {
        sign = 1;
        i++;
      }

      //  Loops until '.'
      while (i < filled && read_buffer[i] != '.') {i++;}
      if (i == filled) break; // Unparsed line - handle carry
      decimal_i = i++;

      //  Loops until '\n'
      //    If no '\n' then one of two things:
      //    we are either at the end of the file
      //    or we are at the end of the buffer
      while (i < filled && read_buffer[i] != '\n') {i++;}
      if (i == filled) {
        if (!eof) break;
        nl_i = filled;
      } else {
        nl_i = i;
        i++;
      } // Unparsed line - handle carry


      // LINE PARSING
      //    line_start_i - beginning of parsed line
      //    semicolon_i - index of semicolon
      //    sign - 1 if negative, 0 if positive
      //    decimal_i - index of decimal point '.'
      //    nl_i - index of newline character (sometimes zero!)

      int temp;
      int temp_whole;
      int temp_tenths;

      //  Getting temp by parsing:
      temp_whole = 
        ((String)read_buffer[
          (semicolon_i+1+sign)..decimal_i-1
        ]).to_int()!;
      temp_tenths =
        ((String)read_buffer[(decimal_i+1):1]).to_int()!;
      temp = sign ? -(temp_whole * 10 + temp_tenths) : 
        (temp_whole * 10 + temp_tenths);

      //  Check Max
      if (temp > analysis.max) {
          //  Record station and temp into analysis
          analysis.max = temp;
          analysis.max_station_length = 
            semicolon_i - line_start_i;
          analysis.max_station_buffer[:analysis.max_station_length] =
            read_buffer[line_start_i..(semicolon_i-1)];
      }

      //  Check Min
      if (temp < analysis.min) {
          //  Record station and temp into analysis
          analysis.min = temp;
          analysis.min_station_length = 
            semicolon_i - line_start_i;
          analysis.min_station_buffer[:analysis.min_station_length] =
            read_buffer[line_start_i..(semicolon_i-1)];
      }



      analysis.total += (long)temp;
      analysis.lines_read++;
      line_start_i = i;
      // LINE PARSING END
    }

    //  Here is where `break` takes us
    //    We have hit i == filled (carry + read_buffer)
    //    NOTE: i-1 here is the last readable character in read_buffer

    carry = filled - line_start_i;
    if (carry > 0) {
      mem::move(&read_buffer[0], &read_buffer[line_start_i], carry);
    }
    if (eof && carry > 0) {
      return io::EOF~;
    }

  }

  // Calculate average after totals
  analysis.avg = analysis.total / analysis.lines_read;


  io::printn("Finished Parsing");
  io::printfn(" Parsed %d lines", analysis.lines_read);
  print_analysis(analysis)!;
  
}






fn File? open_input_file(String input_path) {
  if (input_path.len > 0) {
    return file::open(input_path, "rb");
  }
  
  // Succeeds if ran from root
  if (file::exists(DEFAULT_PROJECT_ROOT_INPUT)) {
    return file::open(DEFAULT_PROJECT_ROOT_INPUT, "rb");
  }
  
  //  Succeeds if ran from build directory
  if (file::exists(DEFAULT_BUILD_DIR_INPUT)) {
    return file::open(DEFAULT_BUILD_DIR_INPUT, "rb");
  }

  return io::FILE_NOT_FOUND~;
}

fn void? print_analysis(Analysis *analysis) {
  io::printn("--Printing Analysis--");
  
  //  Track polarity
  bool neg;
  int mag;

  // neg and mag set absolute value, neg is used to print
  neg = analysis.min < 0;
  mag = neg ? -analysis.min : analysis.min;
  int min_whole = mag / 10;
  int min_tenths = mag % 10;

  //  Print Minimum
  io::printfn("   Minimum Station Temp: %s%d.%d, %s",
    neg ? "-" : "",
    min_whole, min_tenths,
    (String)analysis.min_station_buffer[
      :analysis.min_station_length
    ]
  );

  neg = analysis.max < 0;
  mag = neg ? -analysis.max : analysis.max;
  int max_whole = mag / 10;
  int max_tenths = mag % 10;


  //  Print Maximum
  io::printfn("   Maximum Station Temp: %s%d.%d, %s",
    neg ? "-" : "",
    max_whole, max_tenths,
    (String)analysis.max_station_buffer[
      :analysis.max_station_length
    ]
  );

  //  Pring Average
  neg = analysis.avg < 0;
  mag = (int)(neg ? -analysis.avg : analysis.avg);
  int avg_whole = mag / 10;
  int avg_tenths = mag % 10;
  
  io::printfn("   Average Temp: %s%d.%d",
    neg ? "-" : "",
    avg_whole, avg_tenths
  );



  io::printfn("   Total Reads: %d", analysis.lines_read);
  io::printfn("");
  
}
