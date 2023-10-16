--SELECT *
--FROM CovidVaccinations
--ORDER BY 3, 4

-- Select data we'll be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
ORDER BY 1, 2

---- Looking at total cases vs total deaths
-- Shows the likelihood of dying from COVID in the UK (my country)
Select location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS death_percentage
From CovidProject..CovidDeaths
WHERE location LIKE '%united kingdom%'
order by 1,2

-- Looking at total cases vs population. SHow what percetnage of the UK has gotten COVID
Select location, date, total_cases, population, (total_cases/population) * 100 AS contracted_covid_percentage
From CovidProject..CovidDeaths
WHERE location LIKE '%united kingdom%'
order by 1,2

---- Looking at countries with the highest infection rate compared to population - WRONG??
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS percent_of_pop_infected
From CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_of_pop_infected DESC

-- Showing the countries with the highest death count per population
SELECT location, MAX(cast(total_deaths AS INT)) as total_death_count
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Breaking things down by continent
SELECT location, MAX(cast(total_deaths AS INT)) as total_death_count
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Showing the continents with the highest death count per popuplation
SELECT continent, MAX(cast(total_deaths AS INT)) as total_death_count
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- GLOBAL NUMBERS

-- Death percentage each day
Select date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 as death_percentage
From CovidProject..CovidDeaths
WHERE continent IS NOT NULL
AND new_cases != 0
GROUP BY date
order by 1,2

-- Death percentage overall
Select SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 as death_percentage
From CovidProject..CovidDeaths
WHERE continent IS NOT NULL
AND new_cases != 0
order by 1,2

-- COVID Vaccinations Table

-- Looking at total population vs vaccinations
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations, SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY deaths.location
		ORDER BY deaths.location, deaths.date) AS cumulative_vaccinations
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vax 
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2, 3

-- Looking at total population vs vaccinations - with CTE table
WITH pop_vs_vax (continent, location, date, population, new_vaccinations, cumulative_vaccinations)
AS 
(
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations, SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY deaths.location
			ORDER BY deaths.location, deaths.date) AS cumulative_vaccinations
	FROM CovidProject..CovidDeaths deaths
	JOIN CovidProject..CovidVaccinations vax 
		ON deaths.location = vax.location
		AND deaths.date = vax.date
	WHERE deaths.continent IS NOT NULL
	--ORDER BY 2, 3
)
SELECT *, (cumulative_vaccinations/population) * 100
FROM pop_vs_vax

-- Looking at total population vs vaccinations - with temp table
DROP TABLE IF EXISTS #PercentOfPopulationVaxxed
CREATE TABLE #PercentOfPopulationVaxxed
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	cumulative_vaccinations numeric
)

INSERT INTO #PercentOfPopulationVaxxed
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations, SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY deaths.location
		ORDER BY deaths.location, deaths.date) AS cumulative_vaccinations
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vax 
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
-- ORDER BY 2, 3
SELECT *, (cumulative_vaccinations/population) * 100
FROM #PercentOfPopulationVaxxed

-- Creating view to store data for later visualisations
CREATE VIEW PercentOfPopulationVaxxed AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations, SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY deaths.location
		ORDER BY deaths.location, deaths.date) AS cumulative_vaccinations
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vax 
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL

SELECT * FROM PercentOfPopulationVaxxed;