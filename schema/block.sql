CREATE TABLE block (
       epoch_no UINTEGER,
       slot_no UBIGINT,
       block_time TIMESTAMP,
       block_size UINTEGER,
       tx_count UINTEGER,
       sum_tx_fee DECIMAL,
       script_count UINTEGER,
       sum_script_size UBIGINT,
       pool_hash VARCHAR);
