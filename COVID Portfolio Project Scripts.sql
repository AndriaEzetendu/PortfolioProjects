select * from CovidDeaths 
where continent is not null
order by 3,4

select * from CovidVaccinnations
where continent is not null
order by 3,4

--select data we are using

select location,date,total_cases,new_cases,total_deaths,population from CovidDeaths 
order by 1,2

--total cases vs total deaths
--shows % of covid deaths per location 
select location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
where continent is not null
--and location like '%states%'
order by 1,2

--total cases vs population
--shows % of population has been infected by covid
select location,date,population,total_cases, (total_cases/population)*100 as InfectedPopulationPercentage
from CovidDeaths
where continent is not null
and location like '%states%'
order by 1,2

--countries with highest infection rate compared to population
select location,population,max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as InfectedPopulationPercentage
from CovidDeaths
where continent is not null
--and location like '%states%'
group by location,population
order by 4 desc

--countries with highest death count per location
select location,max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is not null
--and location = 'Canada'
group by location
order by TotalDeathCount desc

--grouping by CONTINENT
--continents with highest death counts per population
select continent,max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is not null
--and location = 'nigeria'
group by continent
order by TotalDeathCount desc

--GLOBAL NUMBERS
--per date since Jan 23, 2020
select date,SUM(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/SUM(new_cases)*100 as GlobalDeathPercentage 
from CovidDeaths
where continent is not null
--and location like '%states%'
group by date
order by 1,2

--total_cases vs total_deaths in % (global)
select SUM(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/SUM(new_cases)*100 as GlobalDeathPercentage 
from CovidDeaths
where continent is not null
--and location like '%states%'
order by 1,2

--JOINING covidDeaths & covidVaccinations tables
select * from CovidDeaths dea
join CovidVaccinnations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
and vac.continent is not null

--total populations vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from CovidDeaths dea
join CovidVaccinnations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
and vac.continent is not null
order by 2,3

--total populations vs vaccinations, using PARTITION BY function to roll over the sum of vaccinated people per location(ordered by location & date)
--The "PARTITION BY" function in SQL is used to divide the result set of a query into partitions, or groups, based on one or more specified columns. This allows you to perform aggregate functions, such as SUM, COUNT, AVG, or RANK, on each partition separately, instead of on the entire result set.
--syntax --->  OVER(PARTITION BY ...)
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinnations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
and vac.continent is not null
order by 2,3

--Using CTE (Common Table Expression)
--A CTE is a temporary named result set that can be referenced within a SQL statement. CTEs provide a way to simplify complex queries, improve query readability, and reuse query logic.
--A CTE is defined within a WITH clause, followed by a SELECT statement that references the CTE. 

--% of total vaccination per population
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinnations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
and vac.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/population)*100 as VaccinatedPopulation
from PopvsVac

--USING TEMP TABLE
--sum of % of total vaccination per population location

drop table if exists #PercentVaccinatedPopulation
create table #PercentVaccinatedPopulation
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated bigint
)

insert into #PercentVaccinatedPopulation
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinnations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 
--and vac.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/population)*100 as VaccinatedPopulation
from #PercentVaccinatedPopulation

--CREATING VIEWS to store data for visualization later
--creating VIEW to show vaccinated population %
CREATE VIEW PercentVaccinatedPopulation as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinnations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null 

select * from PercentVaccinatedPopulation

--creating VIEW to show countries with highest infection rate compared to population
CREATE VIEW InfectedPopulationPercentage as
select location,population,max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as InfectedPopulationPercentage
from CovidDeaths
where continent is not null
--and location like '%states%'
group by location,population

select * from InfectedPopulationPercentage

--creating VIEW to show countries with highest death count per location
CREATE VIEW TotalDeathCountPerLocation as
select location,max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is not null
--and location = 'Canada'
group by location

select * from TotalDeathCountPerLocation
