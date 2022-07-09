SELECT * 
  FROM coviddeaths 

SELECT * 
  FROM covidvaccinations 

-- (select data that we are going to be using)
SELECT location , date , total_cases , new_cases , total_deaths, population 
  FROM coviddeaths
 ORDER BY  1,2
 
-- (looking at total cases vs total deaths) 
SELECT location , date , total_cases , total_deaths , 
       (total_deaths::REAL / total_cases::REAL)* 100  death_percentage ,
  FROM coviddeaths 
 WHERE location LIKE '%States%'
 ORDER BY 1,2

-- (looking at total cases vs population )
SELECT location , date , total_cases , population , 
       (total_cases::REAL / population::REAL)* 100  cases_percentage 
  FROM coviddeaths 
 WHERE location LIKE '%States%'
 ORDER BY 1,2

-- (looking at countries with highest infection rate compared to population )
WITH cte AS 
(
SELECT location , date , total_cases , population , 
       (total_cases::REAL / population::REAL)* 100  cases_percentage 
  FROM coviddeaths 
 ORDER BY 1,2
)

SELECT location ,MAX(cases_percentage) 
  FROM cte
 GROUP BY location 
 ORDER BY 2 DESC NULLS LAST
 
-- (showing countries with highest death count per population) 
WITH cte2 AS 
(
SELECT location , continent , date , total_deaths::INT , population , 
       (total_deaths::REAL / population::REAL)* 100  death_percentage 
  FROM coviddeaths 
  WHERE continent IS NOT NULL
 ORDER BY 1,2
)

SELECT location , SUM(total_deaths) total_deaths_per_country
  FROM cte2
 WHERE continent IS NOT NULL
 GROUP BY 1
 ORDER BY 2 DESC NULLS LAST

-- (Drill up by continent)
WITH cte AS 
(
SELECT location, continent , date , total_cases , population , 
       (total_cases::REAL / population::REAL)* 100  cases_percentage 
  FROM coviddeaths 
 WHERE continent IS  NULL
 ORDER BY 1,2
)

SELECT location  , MAX(total_cases)
  FROM cte 
 WHERE continent IS NULL
 GROUP BY location 
 ORDER BY 2 DESC

-- (showing continents with the highest death count per population) 
SELECT continent , MAX(total_deaths::integer) 
  FROM coviddeaths
 WHERE continent IS NOT NULL AND (location NOT IN ('World','International'))
 GROUP BY continent 
 ORDER BY 2 DESC;

-- (global numbers)
SELECT SUM(new_cases::INTEGER) new_cases, SUM(new_deaths::INTEGER) new_deaths,
       (SUM(new_deaths::REAL)/SUM(new_cases::REAL))*100 death_percentage
  FROM coviddeaths 
 WHERE continent IS NOT NULL 
 ORDER BY 1,2,3 NULLS LAST

--(lookign at total population vs vaccinations)
SELECT cd.continent , cd.location , cd.date , cd.population , cv.new_vaccinations,
       SUM(cv.new_vaccinations::INTEGER) 
           OVER (PARTITION BY cd.location ORDER BY cd.location , cd.date) rolling_people_vaccinated 
  FROM coviddeaths cd
  JOIN covidvaccinations cv
    ON cd.location = cv.location AND cd.date = cv.date 
 WHERE cd.continent IS NOT NULL
 ORDER BY 2 , 3 

-- (using cte) 
WITH cte (continent,loaction , date , population ,new_vaccinations, rolling_people_vaccinated) AS 
(
SELECT cd.continent , cd.location , cd.date , cd.population , cv.new_vaccinations,
       SUM(cv.new_vaccinations::INTEGER) 
           OVER (PARTITION BY cd.location ORDER BY cd.location , cd.date) rolling_people_vaccinated 
  FROM coviddeaths cd
  JOIN covidvaccinations cv
    ON cd.location = cv.location AND cd.date = cv.date 
 WHERE cd.continent IS NOT NULL
 ORDER BY 2 , 3 
)

SELECT *, (rolling_people_vaccinated/population)*100 people_vaccinated
  FROM cte
  
--(create temp table) 
DROP TABLE IF EXISTS percentpopulationvaccinated
CREATE TEMP TABLE percentpopulationvaccinated
(
continent VARCHAR(255),
location VARCHAR(255),
date DATE,
population NUMERIC,
new_vaccinations NUMERIC,
rollingpeoplevaccinated NUMERIC
)

INSERT INTO percentpopulationvaccinated
SELECT cd.continent , cd.location , cd.date , cd.population , cv.new_vaccinations::NUMERIC,
       SUM(cv.new_vaccinations::INTEGER) 
           OVER (PARTITION BY cd.location ORDER BY cd.location , cd.date) rolling_people_vaccinated 
  FROM coviddeaths cd
  JOIN covidvaccinations cv
    ON cd.location = cv.location AND cd.date = cv.date 
 WHERE cd.continent IS NOT NULL
 ORDER BY 2 , 3 
 
SELECT *
  FROM percentpopulationvaccinated
  
--(create view to store data for later visualizations) 
CREATE VIEW percentpopulationvaccinated AS
SELECT SUM(new_cases::INTEGER) new_cases, SUM(new_deaths::INTEGER) new_deaths,
       (SUM(new_deaths::REAL)/SUM(new_cases::REAL))*100 death_percentage
  FROM coviddeaths 
 WHERE continent IS NOT NULL 
 ORDER BY 1,2,3 NULLS LAST

-- queries used for tableau visualization

--1 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
       SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
  From coviddeaths
--Where location like '%states%'
 where continent is not null 
--Group By date
 order by 1,2



-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
--From PortfolioProject..CovidDeaths
----Where location like '%states%'
--where location = 'World'
----Group By date
--order by 1,2


-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
  From coviddeaths
--Where location like '%states%'
 Where continent is null 
       and location not in ('World', 'European Union', 'International')
 Group by location
 order by TotalDeathCount desc


-- 3.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
  From coviddeaths
--Where location like '%states%'
 Group by Location, Population
 order by PercentPopulationInfected desc


-- 4.


Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  
       Max((total_cases/population))*100 as PercentPopulationInfected
  From coviddeaths
--Where location like '%states%'
 Group by Location, Population, date
 order by PercentPopulationInfected desc
