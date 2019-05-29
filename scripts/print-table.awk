#!/usr/bin/awk -f

function truncate(s) {
    return substr(s, 1, columns)
}

BEGIN   { if (columns < 80)
	      columns = 80;
	  if (columns > 240)
	      columns = 240;
	  equals = dashes = "";
	  for (i = 0; i < columns; i++) {
	      dashes = dashes "-";
	      equals = equals "="}
	  header = truncate(header) }
NR == 1 { line1 = truncate($0) }
NR == 2 { printf("%s\n", equals);
	  if (header)
	      printf("%s\n%s\n%s\n", header, dashes, line1)
	  else
	      printf("%s\n%s\n", line1, dashes)}
NR >= 2 { printf("%s\n", truncate($0)) }
END     { if (footer)
	      printf("%s\n", equals) }
