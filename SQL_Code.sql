# Final Project - Tripti Agarwal, Seong Hee Park 

SELECT * FROM Finals.covid;

# Dropping columns that provide redundant data
ALTER TABLE covid
DROP COLUMN confirmed_diff,
DROP COLUMN deaths_diff,
DROP COLUMN recovered_diff,
DROP COLUMN active_diff,
DROP COLUMN recovered;

# Creating the 1st relational table
SET @row_number=0;
DROP TABLE IF EXISTS country_province;
CREATE TABLE IF NOT EXISTS country_province AS
SELECT (@row_number :=@row_number +1) AS cp_id_n, t1.*   # auto-increment
FROM
(SELECT DISTINCT  CONCAT(country_name,'_',province) AS cp_id, iso, country_name, province, latitude, 
longitude FROM covid ORDER BY iso) AS t1;

# Creating another table to join the stats table based on ID created in first table
DROP TABLE IF EXISTS covid_stat;
CREATE TABLE IF NOT EXISTS covid_stat AS
(SELECT DISTINCT CONCAT(country_name,'_',province) AS cp_id, observed_date,confirmed,deaths,
last_update,active_cases FROM covid ORDER BY observed_date);

# Creating the 2nd relational table
DROP TABLE IF EXISTS final_stat;
CREATE TABLE IF NOT EXISTS final_stat AS
(SELECT cp.cp_id_n, cs.observed_date, cs.confirmed, cs.deaths, cs.last_update, 
cs.active_cases FROM covid_stat AS cs
LEFT JOIN country_province AS cp
ON cs.cp_id = cp.cp_id);

# Dropping redundant table
DROP TABLE IF EXISTS covid_stat;

# Creating primary keys
ALTER TABLE `Finals`.`country_province` 
CHANGE COLUMN `cp_id_n` `cp_id_n` BIGINT NOT NULL ,
ADD PRIMARY KEY (`cp_id_n`);
;

ALTER TABLE `Finals`.`final_stat` 
CHANGE COLUMN `cp_id_n` `cp_id_n` BIGINT NOT NULL ,
CHANGE COLUMN `observed_date` `observed_date` DATE NOT NULL ,
ADD PRIMARY KEY (`cp_id_n`, `observed_date`);
;

# Adding foreign keys
ALTER TABLE `Finals`.`final_stat` 
ADD CONSTRAINT `cp_id_n`
  FOREIGN KEY (`cp_id_n`)
  REFERENCES `Finals`.`country_province` (`cp_id_n`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;
 
 
## Creating a view for new cases and new deaths to visualise patterns in rate of case spread on Tableau
CREATE OR REPLACE VIEW `new_cases` AS
SELECT observed_date,confirmed,deaths,last_update,active_cases,fatality_rate,country_name,province,latitude,longitude,
		deaths-ldeaths AS deaths_diff, confirmed-lconfirmed AS confirmed_diff FROM 
(SELECT *, lag(confirmed) OVER (PARTITION BY country_name, province ORDER BY observed_date) AS lconfirmed, 
lag(deaths) OVER (PARTITION BY country_name, province ORDER BY observed_date) AS ldeaths FROM Finals.covid
ORDER BY country_name, province, observed_date) AS t1;