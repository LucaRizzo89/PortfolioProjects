/* This project will focus on data cleaning of the dataset 'NashvilleHousing' */


SELECT *
FROM NashvilleHousing

SELECT SaleDate
FROM NashvilleHousing

/* The first thing we will do is to change the 'SaleDate' column has it contains a timestamp '00.00.00.000' in every row, so we are going to convert
it into a standard date format yyyy-mm-dd. */

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing DROP COLUMN SaleDate

SELECT *
FROM NashvilleHousing

/* As we can see, the 'SaleDate' column is not anymore in our data set, while we now have the 'SaleDateConverted' column in the format that we 
wanted. */ 

SELECT PropertyAddress
FROM NashvilleHousing
WHERE PropertyAddress IS NULL

/* Here we notice that the 'PropertyAddress' column has null values. Since from the dataset we can see that there is a relationship between
the columns 'PropertyAddress' and 'ParcelID', then we could check whether identycal ParcelIDs are translated into identycal Property Addresses. */

SELECT *
FROM NashvilleHousing
ORDER BY ParcelID

/* We can see that this is the case, so we can just fill the NULL values of the 'PropertyAddress' column if the ParcelID of the same row is identycal
to the ParcelID of another row. To do this, we will use a self join since we have the 'UniqueID' column which could be considered as a primary
key in this case.*/

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL

/* As we can see, now we have no null values in the 'PropertyAddress' column. */

SELECT *
FROM NashvilleHousing

/* Now we want to split the 'PropertyAddress' column into 2 columns, a 'PropertySplitCity' column and a 'PropertySplitAddress' column. For this
purpose we will use the SUBSTRING function.*/

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255), PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

 SELECT *
 FROM NashvilleHousing

/* Now we want to do the same for the 'OwnerAddress' column, but this time we will split it into 3 columns, one for the state, one for the city and
one for the address. This time we will use PARSENAME, in combination with the REPLACE function to convert the commas into dots, so that the PARSNAME
function will work.*/

SELECT 
PARSENAME (REPLACE (OwnerAddress, ',', '.'), 1),
PARSENAME (REPLACE (OwnerAddress, ',', '.'), 2),
PARSENAME (REPLACE (OwnerAddress, ',', '.'), 3)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255), OwnerSplitCity Nvarchar(255), OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME (REPLACE (OwnerAddress, ',', '.'), 3),
OwnerSplitCity = PARSENAME (REPLACE (OwnerAddress, ',', '.'), 2),
OwnerSplitState = PARSENAME (REPLACE (OwnerAddress, ',', '.'), 1)


SELECT *
 FROM NashvilleHousing

 /* As we can see, we managed to split both the 'PropertyAddress' and the 'OwnerAddress' columns into separate columns for the address, the city
 and the state, so that eventually in our analysis we could filter by city or state. At this point we can get rid of the original columns. */

 ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress

SELECT *
 FROM NashvilleHousing

 SELECT DISTINCT SoldAsVacant
 FROM NashvilleHousing

 /* Here we can see that the column 'SoldAsVacant' has 4 different unique values, 'N', 'Yes', 'Y' and 'No'. We want to change this into
 either 'Yes' or 'No'. */

 SELECT SoldAsVacant, 
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

SELECT DISTINCT SoldAsVacant
FROM NashvilleHousing

/* Now we only have the two unique values that we wanted. Our last data cleaning step will be eliminating duplicates. This time we will use a CTE.*/

SELECT *, ROW_NUMBER() OVER(
		  PARTITION BY ParcelID,
					   PropertySplitAddress,
					   SalePrice,
					   SaleDateConverted,
					   LegalReference
					   ORDER BY 
							UniqueID
							) row_num

FROM NashvilleHousing
ORDER BY ParcelID


WITH CTE_row_num AS (
SELECT *, ROW_NUMBER() OVER(
		  PARTITION BY ParcelID,
					   PropertySplitAddress,
					   SalePrice,
					   SaleDateConverted,
					   LegalReference
					   ORDER BY 
							UniqueID
							) row_num

FROM NashvilleHousing)

SELECT *
FROM CTE_row_num
WHERE row_num > 1 


WITH CTE_row_num AS (
SELECT *, ROW_NUMBER() OVER(
		  PARTITION BY ParcelID,
					   PropertySplitAddress,
					   SalePrice,
					   SaleDateConverted,
					   LegalReference
					   ORDER BY 
							UniqueID
							) row_num

FROM NashvilleHousing)

DELETE 
FROM CTE_row_num
WHERE row_num > 1 

/* Now we can check if we still have duplicates. */

WITH CTE_row_num AS (
SELECT *, ROW_NUMBER() OVER(
		  PARTITION BY ParcelID,
					   PropertySplitAddress,
					   SalePrice,
					   SaleDateConverted,
					   LegalReference
					   ORDER BY 
							UniqueID
							) row_num

FROM NashvilleHousing)

SELECT *
FROM CTE_row_num
WHERE row_num > 1 

/* The output shows no rows this time, which means that our dataset doesn't contain any duplicates now. */




