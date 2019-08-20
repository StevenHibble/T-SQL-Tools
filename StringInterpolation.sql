CREATE OR ALTER FUNCTION [Tools].[StringInterpolation] 
 (@Template VARCHAR(8000)
, @JSON_Row VARCHAR(MAX))
/*
This function replaces a string template with actual values from a JSON-formatted row
The table returns a single column: FormattedString

** Requires SQL Server 2017+ for STRING_AGG (could be rewritten using XML PATH)

EXAMPLE: 
SELECT *
FROM (SELECT [Name] = 'Steven', Adjective = 'internet person', Verb = 'writes helpful(?) SQL functions') [d]
CROSS APPLY Tools.StringInterpolation ('{Steven} is a {Adjective} who {Verb}.', (SELECT [d].* FOR JSON PATH))

Name   | Adjective        | Verb                            | FormattedString
-------+------------------+---------------------------------+-----------------------------------------------------------------
Steven | internet person  | writes helpful(?) SQL functions | Steven is a internet person who writes helpful(?) SQL functions.
*/
RETURNS TABLE
  RETURN
  WITH [CTE_10]
       AS (SELECT [Number]
           FROM(VALUES (1), (1), (1), (1), (1), (1), (1), (1), (1), (1) ) [v]([Number])),
       -------------------
       /* 100 rows (all 1s) */
       [CTE_100]
       AS (SELECT [Number] = 1
           FROM [CTE_10] [a]
                CROSS JOIN [CTE_10] [b]),
       -------------------
       /* 1,000,000 rows max (all 1s) */
       [CTE_1000000]
       AS (SELECT [Number] = 1
           FROM [CTE_100] [a]
                CROSS JOIN [CTE_100] [b]
                CROSS JOIN [CTE_100] [c]),
       -------------------
       /* Numbers "Table" CTE: 1) TOP has variable parameter = DATALENGTH(@Template), 2) Use ROW_NUMBER */
       [CTE_Numbers]
       AS (SELECT TOP (ISNULL(DATALENGTH(@Template), 0)) [Number] = ROW_NUMBER() OVER(ORDER BY (SELECT NULL) )
           FROM [CTE_1000000]),




       -------------------
       /* Returns start of the element after each delimiter */
       [CTE_Var_Start]
       AS (SELECT [Start] = [Number] + 1 -- This 1 is because SUBSTRING is 0-based, so we want to start the next word 1 AFTER the delimiter
           FROM [CTE_Numbers]
           WHERE SUBSTRING(@Template, [Number], 1) = '{'),
       -------------------
       /* Returns start of the element after each delimiter */
       [CTE_Var_End]
       AS (SELECT [End] = [Number] + 1 -- This 1 is because SUBSTRING is 0-based, so we want to start the next word 1 AFTER the delimiter
           FROM [CTE_Numbers]
           WHERE SUBSTRING(@Template, [Number], 1) = '}'),
       -------------------
       /* Returns start of the element after each delimiter */
       [CTE_Vars]
       AS (SELECT [Start]
                , [Path] = SUBSTRING(@Template, [s].[Start], [e].[End] - [s].[Start] - 1)
                , [Variable] = SUBSTRING(@Template, [s].[Start] - 1, [e].[End] - [s].[Start] + 1)
           FROM [CTE_Var_Start] [s]
                CROSS APPLY (SELECT TOP (1) [End]
                             FROM [CTE_Var_End] [e]
                             WHERE [s].[Start] < [e].[End]
                             ORDER BY [e].[End]) [e]),
       -------------------
       /* Returns start of the element after each delimiter */
       [CTE_Replacements]
       AS (SELECT [Start]
                , [Path]
                , [Variable]
                , [Replacement]
           FROM [CTE_Vars]
                CROSS APPLY (SELECT [Replacement] = JSON_VALUE(@JSON_Row, '$[0].' + [Path])) [json]),


       -------------------
       /* Returns start of the element after each delimiter */
       [CTE_Start]
       AS (SELECT [Start] = 1
           UNION ALL
           SELECT [Start] = [Number] + 1 -- This 1 is because SUBSTRING is 0-based, so we want to start the next word 1 AFTER the delimiter
           FROM [CTE_Numbers]
           WHERE SUBSTRING(@Template, [Number], 1) IN ( '{', '}' ) ),
       -------------------
       /* Returns the length of each word by comparing against the NEXT Start */
       [CTE_Lengths]
       AS (SELECT [Start]
                  -- This is NextStart - ThisStart - 1. The "- 1" is to keep the length coming up to (not *including*) the next delimiter
                  -- For the last word, NextStart would be NULL - so we go to the end of @Template instead
                , [Length] = ISNULL(LEAD([Start]) OVER(ORDER BY [Start]) - [Start] - 1, DATALENGTH(@Template) - [Start] + 1)
           FROM [CTE_Start]),
       -------------------
       /* Do the actual split */
       [CTE_Parts]
       AS (SELECT [ID] = ROW_NUMBER() OVER(
                  ORDER BY [Start])
                , [Start]
                , [Original] = SUBSTRING(@Template, [Start], [Length])
           FROM [CTE_Lengths]
           WHERE [Length] > 0)
       SELECT [FormattedString] = STRING_AGG(COALESCE([Replacement], [Original]), '')
       FROM [CTE_Parts] [p]
            LEFT JOIN [CTE_Replacements] [r]
              ON [p].[Original] = [r].[Path]
                 AND [p].[Start] = [r].[Start];
