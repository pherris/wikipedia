Clone, then `bundle install`.

Run it like this:

```
ruby exe.rb
```

> Enter the page title you want to search (e.g. https://en.wikipedia.org/wiki/Tom_Cruise would be "Tom Cruise"):

October 10

# Future
I think a pretty compelling optimization would be to do a search for all the pages linking to the "target" page (e.g. 
Kevin Bacon). In our search of the "from" page (e.g. 'October 10') we would look for links to _any_ of the pages that 
link to the "target" page. This would decrease our search time significantly by creating as many matches as possible
against the widest part of the tree (thus the fewest iterations against at the widest point of the search).
