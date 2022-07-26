USE covid_19
SELECT * 
  FROM covid_deaths
 ORDER BY 3,4 ;

SELECT * 
  FROM covid_vaccinations
 ORDER BY 3,4;

--SELECT data that I am going to be using 
SELECT location, date, total_cases , new_cases , total_deaths , population 
  FROM covid_deaths 
 ORDER BY 1,2 

 --looking at total cases vs total deaths (death_percentage)
 --shows liklihood of dying if you are infected covid in Egypt
CREATE VIEW egypt_death_percentage AS 
SELECT location, date, total_cases , total_deaths , ROUND((total_deaths/total_cases),4)*100 AS death_percentage
  FROM covid_deaths 
 WHERE location = 'Egypt'
-- ORDER BY 1,2 DESC

 --showing total cases vs population 
 --shows what percentage of Egypt's population infected by covid 
CREATE VIEW egypt_infection_percentage AS
SELECT location, date, population , total_cases , ROUND((total_cases/population),4)*100 AS infected_percentage
  FROM covid_deaths 
 WHERE location = 'Egypt'
 --ORDER BY 1,2 

--Showing new_cases,new_deaths per day in egypt , death_percentage per day 
CREATE VIEW egypt_cases_deaths_per_day AS
SELECT date, SUM(new_cases) new_cases , SUM(CAST(new_deaths AS INT)) new_deaths , 
       ROUND(SUM(CAST(new_deaths AS INT))/NULLIF(SUM(new_cases),0)*100,2) death_percentage_per_day
  FROM covid_deaths
 WHERE location = 'Egypt'
 GROUP BY date 
 --ORDER BY 1 

--Showing total_cases , total_deaths in EGYPT
CREATE VIEW egypt_total_cases_deaths AS
SELECT SUM(new_cases) total_cases , SUM(CAST(new_deaths AS INT)) total_deaths , 
       ROUND(SUM(CAST(new_deaths AS INT))/NULLIF(SUM(new_cases),0)*100,2) death_percentage
  FROM covid_deaths
 WHERE location = 'Egypt'
 --ORDER BY 1 

 --Comparing Egypt to world and africa 

--showing countries with highest infection rate compared to population
CREATE VIEW world_highest_infection_rate_compared_population AS
SELECT location, population ,MAX(total_cases) highest_infection_per_country,
         ROUND((MAX(total_cases)/population),4)*100 AS infected_percentage,
		 RANK() OVER (ORDER BY ROUND((MAX(total_cases)/population),4) DESC) highest_infection_rate_compared_to_population_rank
  FROM covid_deaths 
 WHERE continent IS NOT NULL
 GROUP BY location , population 
 --ORDER BY 4 DESC 
 
 --showing countries with highest death count per population 
CREATE VIEW world_highest_death_rate_compared_population AS
SELECT location , MAX(CAST(total_deaths AS INT)) AS total_death_count
  FROM covid_deaths 
 WHERE continent IS NOT NULL
 GROUP BY location 
 --ORDER BY 2 DESC 

--showing countries with highest death count per total_cases 
CREATE VIEW  world_highest_death_per_total_cases AS
SELECT location ,MAX(total_deaths) max_total_deaths,
       MAX(total_cases) max_total_cases, (MAX(total_deaths)/MAX(total_cases))*100 highest_death_per_infections
  FROM covid_deaths 
 WHERE continent IS NOT NULL AND location != 'North Korea'
 GROUP BY location 
 --ORDER BY 4 DESC

--Looking at total population vs total vaccinations 
CREATE VIEW egypt_total_population_vs_total_vaccinations AS
SELECT de.location , de.date , de.population , CAST(va.new_vaccinations AS INT) new_vaccinations ,
	   SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY de.location ORDER BY de.date )  running_total_vaccinations,
	   SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY de.location ) total_vaccinations
  FROM covid_deaths de
  JOIN covid_vaccinations va
    ON de.location = va.location AND de.date = va.date
  WHERE de.location = 'Egypt' AND va.new_vaccinations IS NOT NULL 

--Showing percentage of people vaccninated in egypt 
CREATE VIEW egypt_percentage_people_vaccinated AS
SELECT etpv.location ,etpv.date, new_vaccinations  , running_total_vaccinations , 
       ROUND(running_total_vaccinations/covid_deaths.population *100,2) running_total_percentage_of_people_vaccinated_per_population
  FROM egypt_total_population_vs_total_vaccinations etpv
  JOIN covid_deaths
    ON etpv.location = covid_deaths.location 


--Creating Temp Table-- 
DROP TABLE  IF EXISTS #percentpopulationvaccinated

CREATE TABLE #percentpopulationvaccinated
(
location VARCHAR(255),
date DATE,
population NUMERIC , 
new_vaccinations NUMERIC,
running_total_vacinations NUMERIC,
total_vaccinations NUMERIC
)

INSERT INTO #percentpopulationvaccinated
SELECT de.location , de.date , de.population , CAST(va.new_vaccinations AS INT) new_vaccinations ,
	   SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY de.location ORDER BY de.date )  running_total_vaccinations,
	   SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY de.location ) total_vaccinations
  FROM covid_deaths de
  JOIN covid_vaccinations va
    ON de.location = va.location AND de.date = va.date
  WHERE de.location = 'Egypt' AND va.new_vaccinations IS NOT NULL 

--CREATE CTE
WITH cte (location,date,population,new_vaccinations,running_total_vaccinations,total_vaccinations)
AS
(
SELECT de.location , de.date , de.population , CAST(va.new_vaccinations AS INT) new_vaccinations ,
	   SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY de.location ORDER BY de.date )  running_total_vaccinations,
	   SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY de.location ) total_vaccinations
  FROM covid_deaths de
  JOIN covid_vaccinations va
    ON de.location = va.location AND de.date = va.date
  WHERE de.location = 'Egypt' AND va.new_vaccinations IS NOT NULL 
)
--Showing percentage of people vaccninated in egypt 
SELECT cte.location ,cte.date, new_vaccinations  , running_total_vaccinations , 
       ROUND(running_total_vaccinations/covid_deaths.population *100,2) running_total_percentage_of_people_vaccinated_per_population
  FROM cte 
  JOIN covid_deaths
    ON cte.location = covid_deaths.location 
