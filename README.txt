= kindle-feeds

* http://danielchoi.com/software/kindle-feeds.html

== DESCRIPTION:

kindle-feeds reads a feed list from kindle_feeds.conf, downloads the feeds, and
generates a Kindle-compatiable and optimized HTML file that can be sent to 
YOUR_KINDLE_USERNAME@kindle.com or YOUR_KINDLE_USERNAME@free.kindle.com for conversion 
into an .azw file for reading on the Kindle. 

The first time kindle-feeds is run, it will generate a stub kindle_feeds.conf file
in the same directory. Please edit this file to specify the feeds you want to
download and convert for Kindle reading. Further instructions can be found at the
top of kindle-feeds.conf once it is generated.

== SYNOPSIS:

  kindle-feeds

== REQUIREMENTS:

* hpricot
* feed-normalizer

== INSTALL:

* sudo gem install kindle-feeds

== LICENSE:

(The MIT License)

Copyright (c) 2008 Daniel Choi

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
