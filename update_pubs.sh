#!/bin/zsh

# https://stackoverflow.com/questions/66600105/pandoc-citing-a-full-source
pandoc --citeproc --csl=apa pubs_raw.md -t markdown-citations -o publications.md \
    --lua-filter=/Users/garrettsmith/.pandoc/filters/inline_citation.lua

# Remove unnecessary references section, kludge
sed -i'' -e '/^:::/,$d' publications.md
