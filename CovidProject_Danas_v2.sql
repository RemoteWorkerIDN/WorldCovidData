SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidData..CovidDeath
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidData..CovidDeath
ORDER BY 1,2

--Looking at Cases and Deaths in United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidData..CovidDeath
WHERE location like '%states%'
ORDER BY 1,2

--Looking at Total Cases vs Population in United States
SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectionRate
FROM CovidData..CovidDeath
WHERE location like '%states%'
ORDER BY 1,2

--Looking at Countries with highest infection rate
SELECT location, population,  MAX(total_cases) as HighestInfectionCount 
, Max((total_cases/population)*100) AS InfectionRate
FROM CovidData..CovidDeath
WHERE continent is not null
GROUP BY location, population
ORDER BY InfectionRate DESC

--Looking at Continent with highest infection rate
SELECT continent, Max((total_cases/population)*100) AS InfectionRate
FROM CovidData..CovidDeath
WHERE continent is not null
GROUP BY continent
ORDER BY InfectionRate DESC

--Showing Countries with Highest Death Count per Population
SELECT location, Max(total_deaths) AS DeathRate
FROM CovidData..CovidDeath
WHERE continent is not null
GROUP BY location
ORDER BY DeathRate DESC

--Looking at Continent with highest Death Count per Population
SELECT continent,  MAX(total_deaths) as HighestDeathCount 
, Max((total_deaths/population)*100) AS DeathRate
FROM CovidData..CovidDeath
WHERE continent is not null
GROUP BY continent
ORDER BY DeathRate DESC

--GLOBAL NUMBERS
SELECT 
--date, 
SUM(new_cases) TotalCases, 
SUM(new_deaths) TotalDeath,
CASE
	WHEN SUM(new_cases) = 0 THEN null
	ELSE (SUM(new_deaths)/sum(new_cases))*100 
	END AS DeathPercentage
FROM CovidData..CovidDeath
WHERE continent is not null
--GROUP BY date
ORDER BY 1 

--Looking at Total Population vs Vaccination
Select 
dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/dea.population)*100
From CovidData..CovidDeath dea
JOIN CovidData..CovidVaccine vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--Group by dea.continent, dea.location, dea.date, vac.new_vaccinations, dea.population
order by 2,3

--HOW TO REUSE RollingPeopleVaccinated
--USE CTE

With PopsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select 
dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/dea.population)*100
From CovidData..CovidDeath dea
JOIN CovidData..CovidVaccine vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--Group by dea.continent, dea.location, dea.date, vac.new_vaccinations, dea.population
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population) as RollingVaccinationRate 
From PopsVac
Order by 2,3

--TEMP TABLE VERSION INSTEAD OF CTE
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select 
dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/dea.population)*100
From CovidData..CovidDeath dea
JOIN CovidData..CovidVaccine vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--Group by dea.continent, dea.location, dea.date, vac.new_vaccinations, dea.population
--order by 2,3

Select * 
From #PercentPopulationVaccinated
 

 --Creating View to store data for later visualitations
Create View PercentPopulationVaccinated as
Select 
dea.continent, 
dea.location, 
dea.date, 
vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (Partition by dea.location Order by dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/dea.population)*100
From CovidData..CovidDeath dea
JOIN CovidData..CovidVaccine vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--Group by dea.continent, dea.location, dea.date, vac.new_vaccinations, dea.population
--order by 2,3
