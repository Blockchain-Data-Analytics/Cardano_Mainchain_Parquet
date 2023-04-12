# Extract Cardano on-chain data to Parquet files

[Db-sync](https://github.com/input-output-hk/cardano-db-sync) maps on-chain data for the Cardano blockchain to PostgreSQL.

For extended use cases, instead of querying the database directly we would like to use a computer cluster to run such queries in parallel at MaxSpeed&trade;.

We already provided an export to [BigQuery](https://github.com/input-output-hk/data-analytics-bigquery) on Google's cloud. But this comes with a cost.

Instead, this project let's you export Db-sync's tables to Parquet files which can be queried locally on your machine or in your local network using many computers.

We use [duckdb](https://duckdb.org/) to output Parquet files which can be queried using _duckdb_ or [Spark SQL](https://spark.apache.org/sql/).

## snapshot

get a db-sync snapshot from: https://update-cardano-mainnet.iohk.io/cardano-db-sync/index.html

install it in a PostgreSQL db



## PostgreSQL setup

create a database with name e.g. "cardanomainnet13" and a user with the same name.

also add the views from ext/data-analytics-bigquery.git/schema/views to schema analytics.

first, change the target users in the SQL files in that directory: 

`for F in *.sql; sed -i -e 's/db_sync_master/cardanomainnet13/g;s/db_sync_reader/cardanomainnet13/g'; done`



## copy to Parquet files

then run the continuous export to Parquet files
(create a .pgpass file or set the password in an env. var. PGPASSWORD)

```sh
export PGHOST=host
export PGPORT=5432
export PGDATABASE=cardanomainnet13
export PGUSER=cardanomainnet13
export PGPASSFILE=.pgpass
```

the target path:
```sh
PARQUET_PATH=/usr/local/spark/data
```

```sh
TBL=block  # for example
DBFILE=${TBL}.ddb
INCREMENT=20
./duckdb ${DBFILE} < schema/${TBL}.sql
for E in `seq 0 ${INCREMENT} 500`; do
  echo "exporting ${TBL} from ${E} to $((E+${INCREMENT})) as CSV"
  psql -c "\\copy ( SELECT * FROM analytics.vw_bq_${TBL} WHERE epoch_no >= ${E} AND epoch_no < ${E} + ${INCREMENT} ) to '${TBL}_${E}.csv' csv;"
  ./duckdb -c "COPY ${TBL} FROM '${TBL}_${E}.csv';" ${DBFILE}
done
./duckdb -c "COPY ${TBL} TO '${PARQUET_PATH}/cardano_mainchain/${TBL}.parquet' (FORMAT PARQUET, COMPRESSION SNAPPY);" ${DBFILE}
```

table tx_in_out
---------------

this table is very large and thus we will split it into pieces.
first, generate the CSV files with the above loop.
then, load groups of CSV files into Parquet files.

```sh
TBL=tx_in_out
DBFILE=${TBL}.ddb
INCREMENT=20
for E in `seq 0 ${INCREMENT} 500`; do
    if [ -e $DBFILE ]; then rm -v $DBFILE; fi
    ./duckdb ${DBFILE} < schema/${TBL}.sql
    for F in `seq $E 1 $((E+INCREMENT-1))`; do
        if [ -e ${TBL}_${F}.csv ]; then
            ./duckdb -c "COPY ${TBL} FROM '${TBL}_${F}.csv';" ${DBFILE}
        fi
    done
    ./duckdb -c "COPY ${TBL} TO '${PARQUET_PATH}/cardano_mainchain/${TBL}/${TBL}_${E}.parquet' (FORMAT PARQUET, COMPRESSION SNAPPY);" ${DBFILE}
done

querying those files:

`duckdb -c "SELECT epoch_no, COUNT(*) FROM read_parquet('${PARQUET_PATH}/cardano_mainchain/tx_in_out/tx_in_out*.parquet') GROUP BY epoch_no ORDER BY epoch_no;"`


