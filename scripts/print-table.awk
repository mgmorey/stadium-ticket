#!/usr/bin/awk -f

# print-table: print a table with lines truncated after COLUMNS columns
# Copyright (C) 2018  "Michael G. Morey" <mgmorey@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

function truncate(s) {
    return substr(s, 1, columns)
}

BEGIN {
    if (columns < 80)
        columns = 80;

    if (columns > 240)
        columns = 240;

    equals = dashes = "";

    for (i = 0; i < columns; i++) {
        dashes = dashes "-";
        equals = equals "="
    }

    header = truncate(header)
    is_header = 0;
}

NR == 1 {
    line1 = truncate($0)
}

NR == 2 {
    print equals;
    print header ? header : line1;
    print dashes;

    if (header)
        print line1
}

NR >= 2 {
    print truncate($0)
}

END {
    if (footer)
        print equals
}
