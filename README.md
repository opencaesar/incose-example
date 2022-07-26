# INCOSE Example

## Overview

This is an example developed by INCOSE Patterns Working Group Semantic Technologies for Systems Engineering (ST4SE) Project.

The purpose of the ST4SE Project is to demonstrate:

* the integrated capability to perform two Model-Based Systems Engineering (MBSE) tasks of value;
* with both tasks making use of the same reusable, configurable MBSE Pattern;
* Task 1: generate a specific MBSE model that is a configuration of that MBSE Pattern;
* Task 2: inspect a separately provided MBSE model for conformance to the MBSE Pattern;
* with both tasks performed by a systems engineer aided by contemporary modeling languages and
tooling, bridging semantic technologies and MBSE.

### Why is this of value?

* Generating models that conform to a pre-existing pattern (for a product line, an architectural
framework, an ontology, a standard, etc.) can improve the efficiency, quality, consistency, and
completeness of new models, and provide a pattern-based point of accumulation (through
incremental updates) of organizational learning to impact future models.
* Checking models for consistency against a pre-existing pattern addresses those same values, for
models that were not generated by the above method, or which are modified versions of models generated
by the above method.
* If the same pattern is used for both tasks, the resulting _loop closure_ further increases value.
This project can be of value to your understanding of how to accomplish similar tasks, advancing technical
skills or team performance.

This project has been performed under a Technical Project Plan of the International Council on Systems
Engineering (INCOSE) MBSE Patterns Working Group. INCOSE has a long history of providing its membership
with technical publications for advancing the practice of systems engineering, but these publications have
ordinarily been in the form of traditional “document-style” publications. A secondary purpose of this project
has been for INCOSE to gain experience in the publication and distribution of model-based information, using
contemporary systems and methods that apply to models. A portion of this project involved configurable
patterns for system interfaces, based on an earlier Patterns Working Group Interface Patterns Project.

## Repository Organization

* `src`
	* `oml/incose.org/pwg/s-star` top-level directory for OML vocabularies and descriptions
		* `vocabulary`
			* `interface.oml` human-created expression of the S*Interface Pattern in OML
			* `power-converter.oml` vocabulary specializations for power converters generated by executing the Ruby script `ConvertVocabulary.rb` on `context.csv` (output of the pattern generator)
			* `power-converter-bundle.oml` human-created vocabulary bundle
		* `description`
			* `power-converter.oml` instantiated power converter description generated by executing the Ruby script `ConvertDescription.rb` on `realization.csv` (output of the pattern generator)
			* `power-converter-bundle.oml` human-created description bundle
	* `csv` output files from pattern generator
	* `ruby` conversion scripts to generate OML from pattern generator output
	* `sparql` SPARQL source files for interface pattern audits
* `build` (populated by executing operations below)
	* `frames` results of audit queries in TSV format
	* `oml` imported vocabularies
	* `owl` output of OML-to-OWL converter
	* `reports` reporting output, including reasoner report (`reasoning.xml`)

## Operations

### Clone
```
  git clone https://github.com/opencaesar/incose-example.git
  cd incose-example
```

### Build
```
./gradlew build
```

### Run OWL Reasoner
```
./gradlew owlReason
```

### Load to Fuseki Dataset
```
./gradlew owlLoad
```
Prerequisite: A Fuseki server has started (see below)  

### Run SPARQL Queries
```
./gradlew owlQuery
```
Pre-req: A Fuseki server has started (see below)  

### Start Fuseki Server
```
./gradlew startFuseki
```

### Stop Fuseki Server
```
./gradlew stopFuseki
```
