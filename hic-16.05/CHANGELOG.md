# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

<br>

## [16.05] 2017-09-28
### Added
- Added this CHANGELOG

<br>

## [16.05] 2017-09-29 
### Fixed
- [Trimmomatic uses `TruSeq-PE-2.fa` for paired-end samples](https://github.com/4DGenome/pipelines/commit/13f8f1b8d4343a014d4560fa6bfa5b74afd2858e) (see more [here](https://public_docs.crg.es/mbeato/jquilez/projects/misc/2017-09-27_adapter_removal/2017-09-27_adapter_removal.slides.html))

<br>

## [16.05] 2017-10-04
### Added
- [FastQC is run on the FASTQ(s) with the trimmed reads](https://github.com/4DGenome/pipelines/commit/f4c0ee1233d42bb4f3e32085058d895a3f16130e)

<br>

## [16.05] 2017-10-20
### Added
- [adapt pipeline to loxAfr3 (African elephant) assembly](https://github.com/4DGenome/pipelines/commit/fb553e50f4b05d94f3ea5387198eb918df205c92)

<br>

## [16.05] 2017-11-17
### Added
- [adapt pipeline to falPer2 (Falco peregrinus) assembly](https://github.com/4DGenome/pipelines/commit/0256bb166ba308fb89a3dca1d3734908d3639062)

<br>

## [16.05] 2017-11-29
### Fixed
- found error in `/software/mb/el7.2/anaconda2/envs/latest_tadbit/lib/python2.7/site-packages/pytadbit/hic_data.py`
- error fixed and documented at `/software/mb/el7.2/0README.md`

<br>

## [16.05] 2017-12-13
### Fixed
- [no wild card is used whendefining the path to the input FASTQ](https://github.com/4DGenome/pipelines/commit/e4915f0b11b0aa6fb61ae978d4f69c9a4fae5433); instead, the exact sample ID needs to match

<br>

## [16.05] 2018-01-23
### Added
- [add fix_multicontact_flag.sh and check_and_replace_bam.sh](https://github.com/4DGenome/pipelines/commit/cb63959da244d66009976a0acc33d2b5ae66497b)
### Changed
- [additional threads to fix_multicontact_flag.sh](https://github.com/4DGenome/pipelines/commit/ac2ffd67d90c1b14494799f9612d0aa57a89a173)

<br>

## [_pipeline_version_] YYYY-MM-DD
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security