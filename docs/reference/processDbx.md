<div id="main" class="col-md-9" role="main">

# given a bar-delimited string as produced for dbXrefs in gene\_info, extract the value associated with a given tag

<div class="ref-description section level2">

given a bar-delimited string as produced for dbXrefs in gene\_info,
extract the value associated with a given tag

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
processDbx(x, tag = "Ensembl:")
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    character(1)

-   tag:

    substring to use to find desired value

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
dem = "MIM:611221|HGNC:HGNC:23690|Ensembl:ENSG00000073605|AllianceGenome:HGNC:23690"
processDbx(dem, tag="MIM:")
#> [1] "611221"
```

</div>

</div>

</div>
