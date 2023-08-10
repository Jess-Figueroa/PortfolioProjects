--Checking to make sure data was imported correctly
use PortfolioProject
select * from CovidDeaths$
order by 3,4
select * from CovidVaccinations$
order by 3,4

--Select data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths$
order by location, date

--Looking at total cases vs total deaths; shows the likelihood of dying if ou contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths$
where location like '%states%'
order by location, date

--Looking  at toal cases vs population; shows what percentage of population got covid
select location, date, population, total_cases, (total_cases/population)*100 as 'Percentage Of Pop With Covid'
from CovidDeaths$
where location like '%states%'
order by location, date

--Looking at countries with highest infection rate compared to population
select location, population, max(total_cases) as 'Highest Infection Count', 
Max((total_cases/population))*100 as 'Percentage of Population Infected'
from CovidDeaths$
--where location like '%states%'
Group by location, population
order by 'Percentage of Population Infected' desc

--Looking at countries with highest death count per population
select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is not null
--continent is not null helps with getting rid of locations that served as continents in the table; we just want countries
Group by location
order by TotalDeathCount desc

--Same thing as above just by continent instead of country
select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is null
Group by location
order by TotalDeathCount desc

--KEEP THIS FOR NOW
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths$
where continent is not null
Group by continent
order by TotalDeathCount desc


--Global Numbers by day
Select date, Sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
from CovidDeaths$
where continent is not null
group by date
order by date

--Global number of cases and deaths
Select Sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
from CovidDeaths$
where continent is not null


--Looking at total population vs vaccinations
--How to use partition by to create a rolling count
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(convert(int, vac.new_vaccinations)) over (partition by dea.location 
	order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths$ dea
join CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Using cte to incorporate the percentage of people vaccinated per location and date
with PopvsVac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(convert(int, vac.new_vaccinations)) over (partition by dea.location 
	order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths$ dea
join CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select * , (rollingpeoplevaccinated/population)*100 as percentvacperlocation
from PopvsVac


--Temp table
Drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(convert(int, vac.new_vaccinations)) over (partition by dea.location 
	order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths$ dea
join CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select * , (rollingpeoplevaccinated/population)*100 as percentvacperlocation
from #PercentPopulationVaccinated


--Creating view to store data for later visualizations

create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(convert(int, vac.new_vaccinations)) over (partition by dea.location 
	order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths$ dea
join CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null