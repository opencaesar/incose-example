# INCOSE Example

This is an example developed by INCOSE PWG using [OML](https://github.com/opencaesar/oml)

## Clone
```
  git clone https://github.com/opencaesar/incose-example.git
  cd incose-example
```

## Build
Equivalent to owlReason task
```
./gradlew build
```

## Run OWL Reasoner
```
./gradlew owlReason
```

## Load to Fuseki Dataset
```
./gradlew owlLoad
```
Pre-req: A Fuseki server has started (see below)  

## Run SPARQL Queries
```
./gradlew owlQuery
```
Pre-req: A Fuseki server has started (see below)  

## Start Fuseki Server
```
./gradlew startFuseki
```

## Stop Fuseki Server
```
./gradlew stopFuseki
```
