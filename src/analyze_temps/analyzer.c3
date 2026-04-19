module analyzer;

import std::core::mem;
import std::io;
import std::io::file;

const String DEFAULT_PROJECT_ROOT_INPUT = "resources/generated_temperatures.txt";
const String DEFAULT_BUILD_DIR_INPUT = "../resources/generated_temperatures.txt";

const int READ_BUF_SIZE = 1024 * 1024;


struct Analyzer {

  File temperature_file;
  
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


fn Analyzer? init(String input_path) {

  Analyzer a = {};

  
  a.temperature_file = a.open_file(input_path)!;

  a.min_station_length = 0;
  a.min = int.max;

  a.max_station_length = 0;
  a.max = int.min;

  a.avg = 0;

  a.total = 0;
  a.lines_read = 0;

  return a;
}

fn void? Analyzer.deinit(Analyzer* self) {
  self.temperature_file.close()!;
}

fn File? Analyzer.open_file(Analyzer* self, String input_path) {
  if (input_path.len > 0) {
    return file::open(input_path, "rb");
  }

  if (file::exists(DEFAULT_PROJECT_ROOT_INPUT)) {
    return file::open(DEFAULT_PROJECT_ROOT_INPUT, "rb");
  }

  if (file::exists(DEFAULT_BUILD_DIR_INPUT)) {
    return file::open(DEFAULT_BUILD_DIR_INPUT, "rb");
  }

  return io::FILE_NOT_FOUND~;
}

fn void? Analyzer.print(Analyzer* self) {
  io::printn("--Printing Analysis--");

  bool neg;
  int mag;
  int whole;
  int tenths;

  //  MINIMUM
  neg = self.min < 0;
  mag = neg ? -self.min : self.min;
  whole = mag / 10;
  tenths = mag % 10;

  io::printfn(" Minimum Station Temp: %s%d.%d, %s",
    neg ? "-" : "",
    whole, tenths,
    (String)self.min_station_buffer[
      :self.min_station_length]
  );

  
  //  MAXIMUM
  neg = self.max < 0;
  mag = neg ? -self.max: self.max;
  whole = mag / 10;
  tenths = mag % 10;

  io::printfn(" Maximum Station Temp: %s%d.%d, %s",
    neg ? "-" : "",
    whole, tenths,
    (String)self.max_station_buffer[
      :self.max_station_length]
  );

  
  //  AVERAGE
  neg = self.avg < 0;
  mag = (int)(neg ? -self.avg : self.avg);
  whole = mag / 10;
  tenths = mag % 10;

  io::printfn(" Average Temp: %s%d.%d",
    neg ? "-" : "",
    whole, tenths
  );

  io::printfn(" Total Reads: %d", self.lines_read);
  io::printn("");
}

fn void? Analyzer.analyze(Analyzer* self) {

  char[] read_buffer = mem::alloc_array(char, READ_BUF_SIZE);
  defer mem::free(read_buffer);
  usz carry = 0;


  //  Loops for every read_buff read
  while(true) {
    usz bytes_read = self.temperature_file.read(read_buffer[carry..])!;

    bool eof = bytes_read == 0;
    usz filled = carry + bytes_read;
    usz i = 0;
    usz line_start_i = 0;

    if(filled == 0) break;

    //  Loops every parsed line
    while (i < filled) {
      
      usz semicolon_i = 0;
      usz decimal_i = 0;
      usz nl_i = 0;
      int sign = 0;

      while(i < filled && read_buffer[i] != ';') {i++;}
      if (i == filled) break;
      semicolon_i = i++;
      if (i == filled) break;

      if (read_buffer[i] == '-') { sign = 1; i++; }

      while ( i < filled && read_buffer[i] != '.') {i++;}
      if(i == filled) break;
      decimal_i = i++;

      while (i < filled && read_buffer[i] != '\n') {i++;}
      if (i == filled) {
        if (!eof) break;
        nl_i = filled;
      } else {
        nl_i = i;
        i++;
      }

      int temp;
      int temp_whole;
      int temp_tenths;


      temp_whole = ((String)read_buffer[
        (semicolon_i + 1 + sign)..(decimal_i - 1)
      ]).to_int()!;
      temp_tenths = ((String)read_buffer[
        (decimal_i + 1):1]).to_int()!;
      temp = sign ? -(temp_whole * 10 + temp_tenths) : 
        (temp_whole * 10 + temp_tenths);

      if (temp > self.max) {
        self.max = temp;
        self.max_station_length = semicolon_i - line_start_i;
        self.max_station_buffer[:self.max_station_length] = 
          read_buffer[line_start_i..(semicolon_i - 1)];
      }

      if (temp < self.min) {
        self.min = temp;
        self.min_station_length = semicolon_i - line_start_i;
        self.min_station_buffer[:self.min_station_length] =
          read_buffer[line_start_i..(semicolon_i - 1)];
      }

      self.total += (long)temp;
      self.lines_read++;
      line_start_i = i;

    }

    carry = filled - line_start_i;
    if (carry > 0) {
      mem::move(&read_buffer[0], &read_buffer[line_start_i], carry);
    }
    if (eof && carry > 0) {
      return io::EOF~;
    }
  }

  self.avg = self.total / self.lines_read;

}
