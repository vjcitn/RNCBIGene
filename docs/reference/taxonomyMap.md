<div id="main" class="col-md-9" role="main">

# retrieve a vector of taxonomy names indexed by taxonomy codes

<div class="ref-description section level2">

retrieve a vector of taxonomy names indexed by taxonomy codes

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
taxonomyMap()
```

</div>

</div>

<div class="section level2">

## Note

retrieved from
https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new\_taxdump/taxdump\_readme.txt
Feb 22 2025

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
tmap = taxonomyMap()
tmap['9606']
#>           9606 
#> "Homo sapiens" 
```

</div>

</div>

</div>
