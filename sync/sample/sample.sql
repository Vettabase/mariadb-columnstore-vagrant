CREATE SCHEMA IF NOT EXISTS sample;
USE sample;

CREATE TABLE IF NOT EXISTS sample.words (
    word VARCHAR(128)
)ENGINE=Columnstore;
DELETE FROM sample.words;

LOAD DATA INFILE '/usr/share/dict/british-english-huge' INTO TABLE sample.words (word);