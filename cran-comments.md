## Resubmission
This is a resubmission. In this version I have:

* Written package names and software names in single quotes (e.g. 'Excel') in
  title and description.

* Used if(interactive()){examples} for interactive examples instead of
  \dontrun{}.

The reviewer asked:

> why don't you include these functions in your package 'tidyxl'?

These functions were in the dev version of tidyxl, but Jenny Bryan suggested
that they be put into a separate package, to be a potential lightweight import
in cellranger.

## Test environments

### Local
* Arch Linux 4.13.3-1-ARCH                         R-release 3.4.2  (2017-09-28)

### Win-builder
* Windows Server 2008 (64-bit)                     R-devel   r73242 (2017-09-12)

### Travis
* Ubuntu Linux 14.04.5 LTS                         R-release 3.4.1  (2017-01-27)

### AppVeyor
* Windows Server 2012 R2 (x64) x64 mingw_64        R-devel   r73498 (2017-10-07)

### Rhub
* Debian Linux (x64)                               R-devel   r72972 (2017-07-26)

## R CMD check results
There were no ERRORs or WARNINGs.

There was 1 NOTE:

* Possibly mis-spelled words in DESCRIPTION:
    Tokenise (2:8)
    Tokenises (5:14)

  Those are not misspellings

## Downstream dependencies
There are no downstream dependencies.
