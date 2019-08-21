CREATE OR ALTER FUNCTION [Tools].[StringInterpolation] 
 (@Template VARCHAR(8000)
, @JSON_Row NVARCHAR(MAX))
/*
This function replaces a string template with actual values from a JSON-formatted row
The table returns a single column: FormattedString

** Requires SQL Server 2017+ for STRING_AGG (could be rewritten using XML PATH)

EXAMPLE: 
SELECT *
FROM (SELECT [Name] = 'Steven', Adjective = 'internet person',        Verb = 'writes helpful(?) SQL functions'
      UNION ALL
      SELECT [Name] = 'Cat',    Adjective = 'wonderful wife and mom', Verb = 'wrangles Hibbles') [d]
CROSS APPLY Tools.StringInterpolation ('{Name} is a {Adjective} who {Verb}.', (SELECT [d].* FOR JSON PATH))

Name   | Adjective              | Verb                            | FormattedString
-------+------------------------+---------------------------------+-----------------------------------------------------------------
Steven | internet person        | writes helpful(?) SQL functions | Steven is a internet person who writes helpful(?) SQL functions.
Cat    | wonderful wife and mom | wrangles Hibbles                | Cat is a wonderful wife and mom who wrangles Hibbles.
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
       AS (SELECT TOP (ISNULL(DATALENGTH(@Template), 0)) [Number] = ROW_NUMBER() OVER(
                                                         ORDER BY (SELECT NULL) )
           FROM [CTE_1000000]),
       -------------------

       /* This is tricky. Get each start of each variable or non-variable
          Variables look like {...}
          Non-variables look like }...{ (i.e. the bits between the variables) */
       [CTE_Start]
       AS (SELECT [Type] = 'Text'
                , [Start] = 1
           UNION ALL
           SELECT [Type] = IIF([Char] = '{', 'Variable', 'Text')
                , [Start] = [Number] + 1 -- start *after* the { or }
           FROM [CTE_Numbers]
                CROSS APPLY (SELECT [Char] = SUBSTRING(@Template, [Number], 1)) [c]
           WHERE [Char] IN ( '{', '}' ) ),
       -------------------
  
       /* Pair each "start" with the next to find indicies of each substring */
       [CTE_StringIndicies]
       AS (SELECT [Type]
                , [Start]
                , [End] = ISNULL(LEAD([Start]) OVER(
                                 ORDER BY [Start]) - 1, DATALENGTH(@Template) + 1)
           FROM [CTE_Start]),
       -------------------

       /* Get each substring */
       [CTE_Variables]
       AS (SELECT [Start]
                , [Type]
                , [SubString] = SUBSTRING(@Template, [Start], [End] - [Start])
           FROM [CTE_StringIndicies]),
       -------------------

       /* If it's a variable, replace it with the actual value from @JSON_Row
          Otherwise, just return the original substring */
       [CTE_Replacements]
       AS (SELECT [Start]
                , [Substring] = IIF([Type] = 'Variable', JSON_VALUE(@JSON_Row, '$[0].' + [Substring]), [Substring])
           FROM [CTE_Variables])
       -------------------

       /* Glue it all back together */
       SELECT [FormattedString] = STRING_AGG([Substring], '') WITHIN GROUP (ORDER BY [Start])
       FROM [CTE_Replacements];
