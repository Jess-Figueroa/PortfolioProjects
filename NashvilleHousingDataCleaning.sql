--Data Cleaning: Nashville Housing

select * from PortfolioProject..NashvilleHousing
------------------------------------------------------------------------------------------

--1. Standardize date format; removing time aspect

--Comparing sale date to what we actually want
select SaleDate, CONVERT(date, SaleDate)
from PortfolioProject..NashvilleHousing

Alter table NashvilleHousing
Add SaleDateConverted date

update NashvilleHousing
set SaleDateConverted = CONVERT(date, SaleDate)

--New column is created with correct date format
select SaleDateConverted, CONVERT(date, SaleDate)
from PortfolioProject..NashvilleHousing

--------------------------------------------------------------------------------------------
--2. Populate property address data

--29 rows don't have a property address
select propertyaddress
from PortfolioProject..NashvilleHousing
where PropertyAddress is null

--Use parcelID to self join, isnull to replace null property addresses 
select a.ParcelID, a.PropertyAddress, b. ParcelID, b.PropertyAddress, ISNULL(a.propertyaddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID=b.ParcelID
	and a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null

update a
set propertyaddress = ISNULL(a.propertyaddress, b.propertyaddress)
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID=b.ParcelID
	and a.[UniqueID ]<>b.[UniqueID ]
where a.PropertyAddress is null

--double checking it worked
select *
from PortfolioProject..NashvilleHousing
where PropertyAddress is null

--------------------------------------------------------------------------------------------
--3. Splitting property address into individual columns (address, city)

--Shows that the property addresses are address+city; delimiter = ,
select propertyaddress
from PortfolioProject..NashvilleHousing

--Use charindex to indicate one character before the , to obtain address
--Use charindex to indicate one character after the , to obtain city
select 
SUBSTRING(Propertyaddress, 1, CHARINDEX(',', Propertyaddress)-1) as Addy,
SUBSTRING(Propertyaddress, CHARINDEX(',', Propertyaddress)+1, LEN(PropertyAddress)) as City
from PortfolioProject..NashvilleHousing

--Alter table to include new columns with split address + city
alter table NashvilleHousing
add PropAddress nvarchar(255)

Update NashvilleHousing
set PropAddress = SUBSTRING(Propertyaddress, 1, CHARINDEX(',', Propertyaddress)-1)

alter table NashvilleHousing
add PropCity nvarchar(255)

Update NashvilleHousing
set PropCity = SUBSTRING(Propertyaddress, CHARINDEX(',', Propertyaddress)+1, LEN(PropertyAddress))

--checking work; could just check propaddress/city
select *
from PortfolioProject..NashvilleHousing

------------------------------------------------------------------------------------------------------
--4. Splitting owner address into individual columns (address, city, state) 

--Looking at data
select owneraddress
from PortfolioProject..NashvilleHousing
---where OwnerAddress is not null

--Using parsename to split the address rather than use substring; parsename uses . so replace , for .
select
PARSENAME(replace(Owneraddress, ',', '.'), 3) as OwnrAddress,
PARSENAME(replace(Owneraddress, ',', '.'), 2) as OwnerCity,
PARSENAME(replace(Owneraddress, ',', '.'), 1) as OwnerState
from PortfolioProject..NashvilleHousing

--Update table with new Owner Address
alter table NashvilleHousing
add OwnrAddress nvarchar(255)

Update NashvilleHousing
set OwnrAddress = PARSENAME(replace(Owneraddress, ',', '.'), 3)

alter table NashvilleHousing
add OwnerCity nvarchar(255)

Update NashvilleHousing
set OwnerCity = PARSENAME(replace(Owneraddress, ',', '.'), 2)

alter table NashvilleHousing
add OwnerState nvarchar(255)

Update NashvilleHousing
set OwnerState = PARSENAME(replace(Owneraddress, ',', '.'), 1)

--Check work
select *
from PortfolioProject..NashvilleHousing

-----------------------------------------------------------------------------------------------------
--5. Change Y and N to Yes and No in "Sold as Vacant" field

--Displays count of answers for each distinct answer type
select distinct(SoldAsVacant), COUNT(Soldasvacant)
from PortfolioProject..NashvilleHousing
Group by SoldAsVacant
order by COUNT(soldasvacant)

--using a case statement to transfer Y+N count to Yes+No count
select soldasvacant
, case when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
		end
from PortfolioProject..NashvilleHousing

update NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
		end

--check work
select distinct(SoldAsVacant), COUNT(Soldasvacant)
from PortfolioProject..NashvilleHousing
Group by SoldAsVacant
order by COUNT(soldasvacant)

-------------------------------------------------------------------------------------------------------
--6. Removing Duplicates

--Creating CTE; deleted duplicates
With RowNumCTE as(
select *,
	ROW_NUMBER() over(partition  by parcelID, propertyaddress, saleprice, saledate, legalreference
	order by uniqueID) as row_num
from PortfolioProject..NashvilleHousing
)
delete
from RowNumCTE
where row_num > 1

----------------------------------------------------------------------------------------------------
--7. Delete unused columns; propertyaddress + owneraddress, saledate

alter table portfolioproject..nashvillehousing
drop column OwnerAddress, PropertyAddress

alter table portfolioproject..nashvillehousing
drop column SaleDate

--checking work
Select *
from PortfolioProject..NashvilleHousing