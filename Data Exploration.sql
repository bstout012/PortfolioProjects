/*
COVID 19 Data Exploration - https://ourworldindata.org/covid-deaths

Skills Used:  Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Views, Data Type Conversion
*/

--INFECTION DATA

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY [location], [date]

--Select data related to infections and deaths
SELECT [location], [date], total_cases, new_cases, total_deaths, [population]
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY [location], [date]

--Total cases vs total deaths
SELECT [location], [date], total_cases, total_deaths, (total_deaths / total_cases) * 100 AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY [location], [date]

--Total cases vs population
SELECT [location], [date], [population], total_cases, (total_cases / [population]) * 100 AS infection_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY [location], [date]

--Countries with highest infection percentage
SELECT [location], [population], MAX(total_cases) AS highest_infection_count, MAX(total_cases) / CAST([population] AS float) * 100 AS location_infection_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location], [population]
ORDER BY location_infection_percentage DESC

--Countries with highest death percentage
SELECT [location], [population], MAX(total_deaths) AS highest_death_count, MAX(total_deaths) / CAST([population] AS float) * 100 AS location_death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location], [population]
ORDER BY location_death_percentage DESC

--Regions with highest death percentage
--SELECT [location], [population], MAX(total_deaths) AS highest_death_count, MAX(total_deaths) / CAST([population] AS float) * 100 AS region_death_percentage
--FROM PortfolioProject.dbo.CovidDeaths
--WHERE continent IS NULL
--	AND ([location] NOT LIKE '%income%')
--GROUP BY [location], [population]
--ORDER BY region_death_percentage DESC

--Select continent, [location], [population], MAX(total_deaths) as highest_death_count, MAX(total_deaths) / CAST([population] AS float) * 100 AS region_death_percentage
--FROM PortfolioProject.dbo.CovidDeaths
--WHERE [continent] IS NOT NULL
--GROUP BY [location], [population], [continent]
--ORDER BY region_death_percentage desc

SELECT continent, MAX(total_deaths) AS highest_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_death_count DESC

--Global death percentage
SELECT SUM(new_cases) AS total_cases_calc, SUM(new_deaths) AS total_deaths_calc, SUM(new_deaths) / SUM(CAST(new_cases AS float)) * 100 AS death_percentage_calc
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL

--VACCINATION DATA

SELECT *
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.[location] = vac.[location]
	AND dea.[date] = vac.[date]

--Total population vs vaccinations

--VIA CTE
WITH PopVac(continent, [location], [date], [population], new_vaccinations, rolling_vaccination_count)
AS (
SELECT dea.continent, dea.[location], dea.[date], CONVERT(float,dea.[population]), vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.[location] ORDER BY dea.[location], dea.[date]) AS rolling_vaccination_count
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.[location] = vac.[location]
	AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
)
SELECT *, rolling_vaccination_count / [population] * 100 AS rolling_vaccination_percentage
FROM PopVac

--VIA TEMP TABLE
DROP TABLE IF EXISTS #PopVacTemp

CREATE TABLE #PopVacTemp(
	continent nvarchar(255),
	[location] nvarchar(255),
	[date] datetime,
	[population] bigint,
	new_vaccinations bigint,
	rolling_vaccination_count bigint
)

INSERT INTO #PopVacTemp
SELECT dea.continent, dea.[location], dea.[date], CONVERT(float,dea.[population]), vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.[location] ORDER BY dea.[location], dea.[date]) AS rolling_vaccination_count
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.[location] = vac.[location]
	AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL

SELECT *, rolling_vaccination_count / [population] * 100 AS rolling_vaccination_percentage
FROM #PopVacTemp

--Views for later data visualizations
CREATE VIEW PopulationVaccinationPercentage AS
SELECT dea.continent, dea.[location], dea.[date], CONVERT(float,dea.[population]) AS [population], vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.[location] ORDER BY dea.[location], dea.[date]) AS rolling_vaccination_count
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.[location] = vac.[location]
	AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
