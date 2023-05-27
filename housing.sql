--DATA CLEANING QUERIES

SELECT *
FROM housing_project..housing_data


--STANDARDIZE DATE  FORMAT

ALTER TABLE housing_data
ADD SaleDateConverted Date;

UPDATE housing_project..housing_data
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted, CONVERT(DATE, SaleDate)
FROM housing_project..housing_data


--POPULATE PROPERTY ADDRESS DATA

SELECT *
FROM housing_project..housing_data
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing_project..housing_data a
JOIN housing_project..housing_data b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing_project..housing_data a
JOIN housing_project..housing_data b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


--BREAKING DOWN ADDRESS INTO INDIVIDUAL COULMNS (ADDRESS, CITY, STATE)

SELECT PropertyAddress
FROM housing_project..housing_data

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS Address
FROM housing_project..housing_data

ALTER TABLE housing_project..housing_data
ADD PropertySplitAddress NVARCHAR(255);

UPDATE housing_project..housing_data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE housing_project..housing_data
ADD PropertySplitCity NVARCHAR(255);

UPDATE housing_project..housing_data
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


SELECT OwnerAddress
FROM housing_project..housing_data

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM housing_project..housing_data

ALTER TABLE housing_project..housing_data
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE housing_project..housing_data
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE housing_project..housing_data
ADD OwnerSplitCity NVARCHAR(255);

UPDATE housing_project..housing_data
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE housing_project..housing_data
ADD OwnerSplitState NVARCHAR(255);

UPDATE housing_project..housing_data
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT *
FROM housing_project..housing_data


--CHANGE 'Y' AND 'N' TO 'YES' AND 'NO' IN 'SOLD AS VACANT' FIELD

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM housing_project..housing_data
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END
FROM housing_project..housing_data

UPDATE housing_project..housing_data
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END


--REMOVE DUPLICATES

--VIEW DUPLICATES
WITH RowNumCTE AS(
SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY
						UniqueID
						) row_num
FROM housing_project..housing_data
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--DELETE DUPLICATES
WITH RowNumCTE AS(
SELECT *,
		ROW_NUMBER() OVER(
		PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY
						UniqueID
						) row_num
FROM housing_project..housing_data
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


--DELETE UNUSED COLUMNS

SELECT *
FROM housing_project..housing_data

ALTER TABLE housing_project..housing_data
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE housing_project..housing_data
DROP COLUMN SaleDate
