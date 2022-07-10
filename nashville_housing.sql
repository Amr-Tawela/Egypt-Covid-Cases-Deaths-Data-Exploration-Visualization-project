/* cleaning data for nashville_housing */

SELECT * 
  FROM nashville_housing 
 ORDER BY "ParcelID";

--(standarize date format)
SELECT "SaleDate"::date
  FROM nashville_housing ;

ALTER TABLE nashville_housing
ALTER COLUMN "SaleDate" TYPE date;


--(populate property address data)
ALTER TABLE nashville_housing
RENAME COLUMN "UniqueID " TO "UniqueID";

SELECT a."ParcelID" , a."PropertyAddress",b."ParcelID" , b."PropertyAddress" , 
       COALESCE(a."PropertyAddress",b."PropertyAddress")
  FROM nashville_housing a
  JOIN nashville_housing b
    ON a."ParcelID" = b."ParcelID" AND a."UniqueID" != b."UniqueID"
 WHERE a."PropertyAddress" IS NULL;
 
UPDATE nashville_housing 
   SET "PropertyAddress" = COALESCE(a."PropertyAddress",b."PropertyAddress")
  FROM nashville_housing a
  JOIN nashville_housing b
    ON a."ParcelID" = b."ParcelID" AND a."UniqueID" != b."UniqueID"
 WHERE a."PropertyAddress" IS NULL;
 
--(breaking out property address into individual columns (address,city,state))
SELECT SUBSTRING("PropertyAddress",1, STRPOS("PropertyAddress",',')-1) AS address,
       SUBSTRING("PropertyAddress",STRPOS("PropertyAddress",',')+1,LENGTH("PropertyAddress")) AS city
  FROM nashville_housing ;
  
ALTER TABLE nashville_housing 
ADD COLUMN IF NOT EXISTS propertysplitaddress VARCHAR(255);

UPDATE nashville_housing 
   SET propertysplitaddress = SUBSTRING("PropertyAddress",1, STRPOS("PropertyAddress",',')-1) ;


ALTER TABLE nashville_housing 
ADD COLUMN propertysplitcity  VARCHAR(255);

UPDATE nashville_housing 
   SET propertysplitcity = SUBSTRING("PropertyAddress",STRPOS("PropertyAddress",',')+1,
                           LENGTH("PropertyAddress")) ;

--(breaking out owner address into individual columns (address,city,state))
SELECT a."ParcelID" ,  a."OwnerAddress" ,b."ParcelID" , b."OwnerAddress"
  FROM nashville_housing a
  JOIN nashville_housing b
    ON a."ParcelID" = b."ParcelID" AND a."UniqueID" != b."UniqueID"
 WHERE a."OwnerAddress" IS NULL AND b."OwnerAddress" IS NOT NULL;

SELECT SPLIT_PART("OwnerAddress",',',1) address,
       SPLIT_PART("OwnerAddress",',',2) city,
       SPLIT_PART("OwnerAddress",',',3) state
  FROM nashville_housing ;
  
ALTER TABLE nashville_housing
  ADD COLUMN address VARCHAR(255);

UPDATE nashville_housing 
   SET address = SPLIT_PART("OwnerAddress",',',1) ;
       
ALTER TABLE nashville_housing
  ADD COLUMN city VARCHAR(255);

UPDATE nashville_housing 
   SET city = SPLIT_PART("OwnerAddress",',',2) ;
  
ALTER TABLE nashville_housing
  ADD COLUMN state VARCHAR(255);

UPDATE nashville_housing 
   SET state = SPLIT_PART("OwnerAddress",',',3) ;
   
--(change y and n to yes and no in 'sold as vacant' field)

SELECT "SoldAsVacant" ,
       CASE WHEN "SoldAsVacant"  = 'Y' THEN 'yes'
            WHEN "SoldAsVacant"  = 'Yes' THEN 'yes'
            WHEN "SoldAsVacant"  = 'N' THEN 'no'
            WHEN "SoldAsVacant"  = 'No' THEN 'no'  
        END soldasvacant2
  FROM nashville_housing
 GROUP BY "SoldAsVacant"
 ORDER BY 2;

ALTER TABLE nashville_housing
ADD COLUMN soldasvacant2 VARCHAR(255);

UPDATE nashville_housing
   SET soldasvacant2 =
       CASE WHEN "SoldAsVacant"  = 'Y' THEN 'yes'
            WHEN "SoldAsVacant"  = 'Yes' THEN 'yes'
            WHEN "SoldAsVacant"  = 'N' THEN 'no'
            WHEN "SoldAsVacant"  = 'No' THEN 'no'  
        END;

--(Remove Duplicates)
WITH cte AS 
(
SELECT *,
       ROW_NUMBER() OVER(PARTITION BY "ParcelID","PropertyAddress","SalePrice","SaleDate","LegalReference"
                         ORDER BY "UniqueID") 
  FROM nashville_housing 
 ORDER BY "UniqueID" DESC
)

CREATE VIEW viewname AS
SELECT * 
  FROM 
(
        SELECT *,
               ROW_NUMBER() OVER(PARTITION BY "ParcelID","PropertyAddress","SalePrice","SaleDate","LegalReference"
                                 ORDER BY "UniqueID") 
          FROM nashville_housing 
         ORDER BY "UniqueID" DESC
) cte
 WHERE row_number = 1 



 




