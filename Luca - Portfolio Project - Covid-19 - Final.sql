/* This project will focus on getting global and local stats from a Covid-19 dataset. */
/* To follow along, please click on PortfolioProjects and download the Covid-19.zip file. */

SELECT *
FROM CovidDeaths
ORDER BY location, date

/* Let's start by selecting only the columns of interest. */

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY location, date

/* The following query is used to calculate the Case Fatality Rate(CFR) which is the ratio between confirmed deaths and confirmed cases. */

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS CFR
FROM CovidDeaths
ORDER BY 1,2

/* We can filter by country. */

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS CFR
FROM CovidDeaths
WHERE location like '%italy%'
ORDER BY 1,2

/* As we can see, the CFR was very high at the beginning of the pandemic, meaning that a high percentage of the infected people had died, and it 
progressively went down as the medical community learnt how to treat the patients better, and as the restrictions were put on place by the governments,
allowing the hospitals to handle less people at the same time. */

/* In the following query we will calculate the Percentage of Population Infected (PPI), which is the ratio between confirmed cases and country's
population. */

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PPI
FROM CovidDeaths
--WHERE location like '%italy%'
ORDER BY 1,2

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PPI
FROM CovidDeaths
WHERE location like '%italy%'
ORDER BY 1,2

/* Here we will show the top 100 countries with the highest number of deaths. */

SELECT TOP 100 location, MAX(total_deaths) AS HighestDeathsCount
FROM CovidDeaths
GROUP BY location
ORDER BY HighestDeathsCount DESC

/* From the output of the query we can see that it is not showing the countries with the highest number of total deaths. Perhaps the column 'total deaths'
is not a number datatype. We can cast a numerical datatype for the column 'total_deaths' and see if we get the right output. */

SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathsCount
FROM CovidDeaths
GROUP BY location
ORDER BY HighestDeathsCount DESC

/* This worked better, however, we can see that we have some entries in the 'location' column that we wouldn't expect. This dataset contains a 'continent'
column, therefore the 'location' column should not contain the entries: Europe, South American, Asia etc etc. At this point we need to check the columns
entries more in depth. */


SELECT location, continent
FROM CovidDeaths
WHERE continent IS NULL
ORDER BY location 

/* We can see that all the rows that have the location correspondent to a continent's name have a null value in the column 'continent'. At this point
we should check which column between the two we should use for our stats. */

SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathsCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathsCount DESC

SELECT continent, MAX(cast(total_deaths as int)) AS HighestDeathsCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HighestDeathsCount DESC

/* The output of these two queries tell us that the HighestDeathsCount from the second query is considering only the number from United States when
accounting for North America, not including the numbers from Canada, for instance. At this point we need to check if the numbers from the 'location'
column where 'continent IS NULL' are more trustworthy. */

SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathsCount
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY HighestDeathsCount DESC

/* These values seem to be more realistic. Now we could double check if the World HighestDeathCounts matches with the sum of the rows from all the 
continents(without considering European union, which might include duplicates from the Europe aggregation). */

WITH CTE_TotalDeathsPerContinent AS
(SELECT location, MAX(cast(total_deaths as int)) AS HighestDeathsCount
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
)
SELECT SUM(HighestDeathsCount) AS WorldDeathsCount
FROM CTE_TotalDeathsPerContinent
WHERE location NOT IN ('World', 'European Union')

/* The number from this query matches the HighestDeathCount with location as 'World' from the previous query, therefore the numbers where the column continent is null,
can be trusted. */

/*Now we'll look at some global stats. */

/* The following query will allow us to keep track of the everyday worldwide new cases and deaths, and these will be used to calculate the Daily Global Case Fatality Rate. */

SELECT date, SUM(new_cases) AS WorldDailyNewCases, SUM(CAST(new_deaths AS int)) AS WorldDailyNewDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DailyGlobalCFR
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

/* Here we can see how the DailyGlobalCFR has a different trend with respect to the individual country CFR that we calculated previously, as this
number depends on the impact of the pandemic at the global scale which, in the first part, includes peaks mostly due to the spread of the virus
throughout the world, with countries that couldn't cope with the virus immediately, and in the second part it includes peaks due to the new Covid-19
waves and mutations. However, overall, we can see that the DailyGlobalCFR has been way more stable since the beginning of the vaccination campaign. */


/* The following query will give us just the total number of cases and deaths until today, and the related ratio. */

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS GlobalCFR
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1



/* Next, we will consider the daily new vaccinations, accumulate them and calculate the percentage of people vaccinated, in this case 
filtered by location */


SELECT Dea.continent, Dea.location,Dea.date, Dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY Dea.location, Dea.date) AS PeopleVaccinatedCounter,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY Dea.location, Dea.date)/Dea.population * 100 AS PercentagePeopleVaccinated
FROM CovidDeaths as Dea
JOIN CovidVaccinations as Vac
	ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL --AND Dea.location LIKE 'italy'
ORDER BY 2,3



SELECT Dea.continent, Dea.location,Dea.date, Dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY Dea.location, Dea.date) AS PeopleVaccinatedCounter,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY Dea.location, Dea.date)/Dea.population * 100 AS PercentagePeopleVaccinated
FROM CovidDeaths as Dea
JOIN CovidVaccinations as Vac
	ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL AND Dea.location LIKE 'italy'
ORDER BY 2,3

/* Through this query we can see that the percentage of people vaccinated in some countries exceeds 100%, because in reality this number takes into
account the total number of vaccinations which includes double shots, therefore we would require a 1st dose and a 2nd dose vaccination columns to
extrapolate the real percentage of people vaccinated with 1 or 2 doses. */

/* Now let's see which are the countries with the highest percentage of people vaccinated in the world */

WITH CTE_PopVsVac 
AS 
(
SELECT  Dea.location, Dea.population,
MAX(CAST(Vac.total_vaccinations AS bigint))  AS PeopleVaccinated
FROM CovidDeaths as Dea
JOIN CovidVaccinations as Vac
	ON Dea.location = Vac.location 
WHERE dea.continent IS NOT NULL 
GROUP BY Dea.location, Dea.population
--ORDER BY 1
)
SELECT *, PeopleVaccinated/population*100 AS PercentagePeopleVaccinated
FROM CTE_PopVsVac
ORDER BY PercentagePeopleVaccinated DESC

/* Here we can see how Gibraltar has even exceeded 200%, which would mean that its entire population received 2 vaccination doses, meaning that most
likely people from other countries were able to get their vaccination in Gibraltar. */


/* These queries could be used for data visualization through a software like Tableau or PowerBI. */


