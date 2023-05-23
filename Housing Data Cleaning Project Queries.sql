/*

Nashville Housing Data Cleaning

Skills Used:  Data Type Conversion, Updating/Altering Tables, String Fuctions, Windows Functions, Aggregate Functions, Joins

*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

/*------------------------------------------------------------------------
Standardize Date Format
------------------------------------------------------------------------*/

SELECT SaleDate --, SaleDateConverted
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateConverted Date

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

/*------------------------------------------------------------------------
Populate Property Address
------------------------------------------------------------------------*/

SELECT ParcelID, [UniqueID ], PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

UPDATE A
SET A.PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing AS A
JOIN PortfolioProject.dbo.NashvilleHousing AS B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

/*------------------------------------------------------------------------
Breakout Address Components
------------------------------------------------------------------------*/

SELECT PropertyAddress --, PropertyStreetAddress, PropertyCity
FROM PortfolioProject.dbo.NashvilleHousing

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1) AS [Address],
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertyStreetAddress varchar(255)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertyCity varchar(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress))

/*------------------------------------------------------------------------
Breakout Owner Address Components
------------------------------------------------------------------------*/

SELECT OwnerAddress --, OwnerStreetAddress, OwnerCity, OwnerState
FROM PortfolioProject.dbo.NashvilleHousing

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerStreetAddress varchar(255)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerCity varchar(255)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerState varchar(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

/*------------------------------------------------------------------------
Cleanup Sold As Vacant Column
------------------------------------------------------------------------*/

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant =
	CASE
		WHEN UPPER(SoldAsVacant) = 'N' THEN 'No'
		WHEN UPPER(SoldAsVacant) = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
	END

/*------------------------------------------------------------------------
Remove Duplicates - assume this isn't raw data
------------------------------------------------------------------------*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

WITH RowNumberCTE AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelId, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS RowNumber
FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE --SELECT *
FROM RowNumberCTE
WHERE RowNumber > 1

/*------------------------------------------------------------------------
Delete Unused Columns
------------------------------------------------------------------------*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate,PropertyAddress, OwnerAddress, TaxDistrict
