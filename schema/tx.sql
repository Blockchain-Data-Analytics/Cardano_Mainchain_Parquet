
CREATE TABLE tx (
       epoch_no UINTEGER,
       tx_hash VARCHAR,
       block_time TIMESTAMP,
       slot_no UBIGINT,
       txidx UINTEGER,
       out_sum DECIMAL(31,0),
       fee DECIMAL,
       deposit DECIMAL,
       size UBIGINT,
       invalid_before UBIGINT,
       invalid_after UBIGINT,
       valid_script BOOL,
       script_size UINTEGER,
       count_inputs UINTEGER,
       count_outputs UINTEGER);
